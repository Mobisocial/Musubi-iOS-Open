/*
 * Copyright 2012 The Stanford MobiSocial Laboratory
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


//
//  AMQPSender.m
//  Musubi
//
//  Created by Willem Bult on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AMQPSender.h"
#import "AMQPConnectionManager.h"
#import "NSData+Base64.h"

#import "Musubi.h"
#import "IBEncryptionScheme.h"

#import "PersistentModelStore.h"
#import "FeedManager.h"
#import "EncodedMessageManager.h"
#import "MEncodedMessage.h"
#import "MIdentity.h"

#import "BSONEncoder.h"
#import "Message.h"
#import "Recipient.h"

@implementation AMQPSender {
    int groupProbeChannel;
}

@synthesize declaredGroups, waitingForAck, messagesWaitingCondition = _messagesWaitingCondition;

- (id)initWithConnectionManager:(AMQPConnectionManager *)conn storeFactory:(PersistentModelStoreFactory *)sf {
    self = [super initWithConnectionManager:conn storeFactory:sf];
    if (!self)
        return nil;

    self.waitingForAck = [NSMutableDictionary dictionary];
    self.declaredGroups = [NSMutableSet set];
    groupProbeChannel = -1;
    
    self.messagesWaitingCondition = [[NSCondition alloc] init];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(signalMessagesReady) name:kMusubiNotificationPreparedEncoded object:nil];
    return self;
}

- (void) signalMessagesReady {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(signalMessagesReady) withObject:nil waitUntilDone:NO];
        return;
    }
    
    //[_messagesWaitingCondition lock];
    [_messagesWaitingCondition signal];
    //[_messagesWaitingCondition unlock];
}

- (void)main {
    // Run AMQPThread common
    [super main];
    
    EncodedMessageManager* emm = [[EncodedMessageManager alloc] initWithStore:threadStore];
    
    // Perpetually wait for messages to become available
    while (![[NSThread currentThread] isCancelled]) {
        
        [_messagesWaitingCondition lock];
        
        NSArray* unsent = nil;
        while (unsent == nil || unsent.count == 0) {
            // Timeout is only used in case the connection crashes while messages are still waiting to be sent
            // We can afford a long delay in that border case. In the usual case, we will be signaled
            // as soon as a message is ready.
            [_messagesWaitingCondition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:5]];
            unsent = [emm unsentOutboundMessages];            
        }
        
        while (![connMngr connectionIsAlive]){
            [connMngr initializeConnection];
        }

        @try {
            NSArray* unsent = [emm unsentOutboundMessages];
            
            if (unsent != nil) {
                if (unsent.count > 0)
                    [self log:@"Sending %d messages", unsent.count];
                
                int left = unsent.count;
                for (MEncodedMessage* msg in unsent) {
                    assert(msg.outbound);
                    self.connMngr.connectionState = [NSString stringWithFormat:@"Sending %d messages...", left--];
                    [self sendMessage: msg];
                }
            }
        } @catch (NSException* exception) {
            [self log:@"Crashed in send: %@", exception];
            // Failed to send message, close connection
            [connMngr closeConnection];
        } @finally {
        }
        
        [_messagesWaitingCondition unlock];
    }
    
    [connMngr closeConnection];
}

- (void) sendMessage: (MEncodedMessage*) msg {
    Message* m = [BSONEncoder decodeMessage:msg.encoded];
    
    NSMutableArray* ids = [NSMutableArray arrayWithCapacity:[m.r count]];
    NSMutableSet* hidForQueue = [NSMutableSet setWithCapacity:[m.r count]];
    
    for (int i=0; i<m.r.count; i++) {
        IBEncryptionIdentity* ident = [[[IBEncryptionIdentity alloc] initWithKey:((Recipient*)[m.r objectAtIndex:i]).i] keyAtTemporalFrame:0];
        [hidForQueue addObject: ident];
        
        MIdentity* mIdent = (MIdentity*)[threadStore createEntity:@"Identity"];
        [mIdent setPrincipalHash:[ident hashed]];
        [mIdent setType: [ident authority]];
        [threadStore save];
        [ids addObject:mIdent];
    }
    
    NSData* groupExchangeNameBytes = [FeedManager fixedIdentifierForIdentities: ids];
    //the original android group exchanges were ibegroup and they were durable.  the non-durable version
    //has a t in the name, for temporary.
    NSString* groupExchangeName = [self queueNameForKey:groupExchangeNameBytes withPrefix:@"ibetgroup-"];
    
    
    if (![declaredGroups containsObject:groupExchangeName]) {
        [connMngr declareExchange:groupExchangeName onChannel:kAMQPChannelOutgoing passive:NO durable:NO];
        //[self log:@"Creating group exchange: %@", groupExchangeName];
        
        for (IBEncryptionIdentity* recipient in hidForQueue) {
            NSString* dest = [self queueNameForKey:recipient.key withPrefix:@"ibeidentity-"];
            NSLog(@"Sending message to %@", dest);
            
            if(groupProbeChannel == -1)
                groupProbeChannel = [connMngr createChannel];
            @try {
                // This will fail if the exchange doesn't exist
                [connMngr declareExchange:dest onChannel:groupProbeChannel passive:YES durable:YES];
            } @catch (NSException *exception) {
                [connMngr closeChannel:groupProbeChannel];
                groupProbeChannel = -1;
                [self log:@"Identity change was not bound, define initial queue"];
                
                NSString* initialQueueName = [NSString stringWithFormat:@"initial-%@", dest];
                [connMngr declareQueue:initialQueueName onChannel:kAMQPChannelOutgoing passive:NO durable:YES exclusive:NO];
                [connMngr declareExchange:dest onChannel:kAMQPChannelOutgoing passive:NO durable:YES];
                [connMngr bindQueue:initialQueueName toExchange:dest onChannel:kAMQPChannelOutgoing];
            }
            
            //[self log:@"Binding exchange %@ <= exchange %@", dest, groupExchangeName];
            [connMngr bindExchange:dest to:groupExchangeName onChannel:kAMQPChannelOutgoing];
        }
        [declaredGroups addObject:groupExchangeName];
    }
    
    //[self log:@"Publishing to %@", groupExchangeName];
    
    uint32_t deliveryTag = [connMngr nextSequenceNumber];
    [connMngr publish:msg.encoded to:groupExchangeName onChannel:kAMQPChannelOutgoing];
    
//    [self log:@"Outgoing: %@", msg.encoded];
    
    [waitingForAck setObject:msg forKey:[NSNumber numberWithUnsignedInt:deliveryTag]];
    
    // TODO: wait for ack;
    [self confirmDelivery:deliveryTag succeeded:YES];
}

- (void)confirmDelivery:(uint32_t)deliveryTag succeeded:(BOOL)ack {
    
    NSNumber* key = [NSNumber numberWithUnsignedInt:deliveryTag];
    
    if (ack) {
        MEncodedMessage* msg = [waitingForAck objectForKey:key];
        if (msg == nil) {
            @throw [NSException exceptionWithName:kMusubiExceptionNotFound reason:@"No message for delivery tag" userInfo:nil];
        }
        
        assert (msg.outbound);
        msg.processed = YES;
        [threadStore save];
        
        //[connMngr ackMessage:deliveryTag onChannel:kAMQPChannelOutgoing];
    } else {
        //don't immediately try to resend, just flag it, it will be rescanned later
        //this probably only happens if the server is temporarily out of space
    }
    
    [waitingForAck removeObjectForKey:key];
}


@end
