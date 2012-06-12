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
#import "AMQPUtil.h"
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

@implementation AMQPSender

@synthesize declaredGroups, messagesWaitingCondition = _messagesWaitingCondition;
@synthesize pending = _pending;
@synthesize queue = _queue;
@synthesize connMngr = _connMngr;
@synthesize storeFactory = _storeFactory;
@synthesize groupProbeChannel = _groupProbeChannel;

- (id)initWithConnectionManager:(AMQPConnectionManager *)conn storeFactory:(PersistentModelStoreFactory *)sf {
    self = [super init];
//    self = [super initWithConnectionManager:conn storeFactory:sf];
    if (!self)
        return nil;
    
    _storeFactory = sf;
    _connMngr = conn;
    _queue = [NSOperationQueue new];
    _queue.maxConcurrentOperationCount = 1;
    
    // List of objs pending encoding
    _pending = [NSMutableArray arrayWithCapacity:10];
    
    self.declaredGroups = [NSMutableSet set];
    _groupProbeChannel = -1;
    
    self.messagesWaitingCondition = [[NSCondition alloc] init];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(processMessages:) name:kMusubiNotificationPreparedEncoded object:nil];
    return self;
}

- (void) processMessages: (NSNotification*) notification {
    EncodedMessageManager* emm = [[EncodedMessageManager alloc] initWithStore:[_storeFactory newStore]];
    
    NSMutableArray* ids = [NSMutableArray array];
    for (MEncodedMessage* msg in [emm unsentOutboundMessages]) {
        [ids addObject: msg.objectID];
    }
    
    [self processMessagesWithIds: ids];
}

- (void) processMessagesWithIds: (NSArray*) messageObjectIDs {
    for (NSManagedObjectID* msgId in messageObjectIDs) {
        
        // Don't process the same obj twice in different threads
        // pending is atomic, so we should be able to do this safely
        // Store ObjectID instead of object, because that is thread-safe
        if ([_pending containsObject: msgId]) {
            continue;
        } else {
            [_pending addObject: msgId];
        }
        
        // Find the thread to run this on
        [_queue addOperation: [[AMQPSendOperation alloc] initWithMessageId:msgId andSender:self]];
    }
}

@end 


@implementation AMQPSendOperation

@synthesize sender = _sender, messageId = _messageId;

- (id)initWithMessageId:(NSManagedObjectID *)msgId andSender:(AMQPSender *)sender {
    self = [super init];
    if (self) {
        _sender = sender;
        _messageId = msgId;
    }
    return self;
}

- (void) main {
    PersistentModelStore* store = [_sender.storeFactory newStore];
    NSError* error;
    
    MEncodedMessage* msg = (MEncodedMessage*)[store.context existingObjectWithID:_messageId error:&error];
    if (!msg)
        @throw error;
    
    while (![_sender.connMngr connectionIsAlive]){
        [_sender.connMngr initializeConnection];
    }
    
    @try {
        assert(msg.outbound);
        _sender.connMngr.connectionState = [NSString stringWithFormat:@"Sending %d messages...", _sender.pending.count];
        [self send: msg];
    } @catch (NSException* exception) {
        NSLog(@"Crashed in send: %@", exception);
        // Failed to send message, close connection
        [_sender.connMngr closeConnection];
    } @finally {
    }
    
    // Remove from the pending queue
    [_sender.pending removeObject:_messageId];
}

- (void) send: (MEncodedMessage*) msg {
    Message* m = [BSONEncoder decodeMessage:msg.encoded];
    
    NSMutableArray* ids = [NSMutableArray arrayWithCapacity:[m.r count]];
    NSMutableSet* hidForQueue = [NSMutableSet setWithCapacity:[m.r count]];
    
    if (m.r.count > 100) {
        NSLog(@"Message to more than 100 people, can't deal with this, discarding");
        
        [[msg managedObjectContext] deleteObject:msg];
        [[msg managedObjectContext] save:nil];
        return;
    }
    
    for (int i=0; i<m.r.count; i++) {
        IBEncryptionIdentity* ident = [[[IBEncryptionIdentity alloc] initWithKey:((Recipient*)[m.r objectAtIndex:i]).i] keyAtTemporalFrame:0];
        [hidForQueue addObject: ident];
        
        PersistentModelStore* store = [_sender.storeFactory newStore];
        MIdentity* mIdent = (MIdentity*)[store createEntity:@"Identity"];
        [mIdent setPrincipalHash:[ident hashed]];
        [mIdent setType: [ident authority]];
        [store save];
        [ids addObject:mIdent];
    }
    
    NSData* groupExchangeNameBytes = [FeedManager fixedIdentifierForIdentities: ids];
    //the original android group exchanges were ibegroup and they were durable.  the non-durable version
    //has a t in the name, for temporary.
    NSString* groupExchangeName = [AMQPUtil queueNameForKey:groupExchangeNameBytes withPrefix:@"ibetgroup-"];
    
    
    if (![_sender.declaredGroups containsObject:groupExchangeName]) {
        [_sender.connMngr declareExchange:groupExchangeName onChannel:kAMQPChannelOutgoing passive:NO durable:NO];
        //[self log:@"Creating group exchange: %@", groupExchangeName];
        
        for (IBEncryptionIdentity* recipient in hidForQueue) {
            NSString* dest = [AMQPUtil queueNameForKey:recipient.key withPrefix:@"ibeidentity-"];
            NSLog(@"Sending message to %@", dest);
            
            if(_sender.groupProbeChannel == -1)
                _sender.groupProbeChannel = [_sender.connMngr createChannel];
            @try {
                // This will fail if the exchange doesn't exist
                [_sender.connMngr declareExchange:dest onChannel:_sender.groupProbeChannel passive:YES durable:YES];
            } @catch (NSException *exception) {
                [_sender.connMngr closeChannel:_sender.groupProbeChannel];
                _sender.groupProbeChannel = -1;
                [self log:@"Identity change was not bound, define initial queue"];
                
                NSString* initialQueueName = [NSString stringWithFormat:@"initial-%@", dest];
                [_sender.connMngr declareQueue:initialQueueName onChannel:kAMQPChannelOutgoing passive:NO durable:YES exclusive:NO];
                [_sender.connMngr declareExchange:dest onChannel:kAMQPChannelOutgoing passive:NO durable:YES];
                [_sender.connMngr bindQueue:initialQueueName toExchange:dest onChannel:kAMQPChannelOutgoing];
            }
            
            //[self log:@"Binding exchange %@ <= exchange %@", dest, groupExchangeName];
            [_sender.connMngr bindExchange:dest to:groupExchangeName onChannel:kAMQPChannelOutgoing];
        }
        [_sender.declaredGroups addObject:groupExchangeName];
    }
    
    //[self log:@"Publishing to %@", groupExchangeName];
    
    uint32_t deliveryTag = [_sender.connMngr nextSequenceNumber];
    NSManagedObjectID* obj_id = msg.objectID;
    [_sender.connMngr publish:msg.encoded to:groupExchangeName onChannel:kAMQPChannelOutgoing onAck:[^{
        PersistentModelStore* store = [[Musubi sharedInstance] newStore];
        NSError* error;
        MEncodedMessage* msg = (MEncodedMessage*)[store.context existingObjectWithID:obj_id error:&error];
        assert(msg.outbound);
        msg.processed = YES;
        [store save];

    } copy]];
}

- (void) log:(NSString*) format, ... {
    va_list args;
    va_start(args, format);
    NSLogv([NSString stringWithFormat: @"AMQPTransport %p: %@", self, format], args);
    va_end(args);
}

@end
