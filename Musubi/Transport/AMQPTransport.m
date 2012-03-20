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
//  AMQPTransport.m
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AMQPTransport.h"
#import "FeedManager.h"
#import "NSData+Base64.h"
#import "EncodedMessageManager.h"
#import "Musubi.h"

@implementation AMQPTransport

static int instanceCount = 0;

@synthesize connMngr, connMgrOut, transportDataProvider, declaredGroups, waitingForAck, messageManager, deviceManager, identityManager, inThread, outThread;

- (id)initWithTransportDataProvider:(id<TransportDataProvider>)tdp {
    self = [super init];
    if (self) {
        [self setConnMngr:[[[AMQPConnectionManager alloc] init] autorelease]];
        [self setConnMgrOut:[[[AMQPConnectionManager alloc] init] autorelease]];
//        [self setConnMgrOut:connMngr];
        
        [self setDeclaredGroups: [NSMutableArray array]];
        [self setWaitingForAck: [NSMutableDictionary dictionary]];
        
        [self setTransportDataProvider: tdp];
        
        [self setMessageManager: [[[EncodedMessageManager alloc] initWithStore: [tdp store]] autorelease]];
        [self setDeviceManager: [[[DeviceManager alloc] initWithStore:[tdp store]] autorelease]];
        [self setIdentityManager: [[[IdentityManager alloc] initWithStore: [tdp store]] autorelease]];
        
        instance = instanceCount++;
    }
    return self;
}

- (void) start {
    [self startListener];
    [self startSender];
}

- (void) startListener {
    stopListener = NO;
    [self setInThread: [[[NSThread alloc] initWithTarget:self
                                                 selector:@selector(listen)
                                                   object:nil] autorelease]];
    [inThread start];
}

- (void) startSender {
    
    stopSender = NO;
    [self setOutThread: [[[NSThread alloc] initWithTarget:self
                                                  selector:@selector(send)
                                                    object:nil] autorelease]];
    [outThread start];
}

- (void)stop {
    stopListener = YES;
    stopSender = YES;
}

- (BOOL)done {
    return [inThread isFinished] && [outThread isFinished];
}


- (NSString*) queueNameForKey: (NSData*) key withPrefix: (NSString*) prefix {
    return [NSString stringWithFormat:@"%@%@", prefix, [key encodeBase64]];
}


- (void) log:(NSString*) format, ... {
    va_list args;
    va_start(args, format);
    NSLogv([NSString stringWithFormat: @"AMQPTransport %d: %@", instance, format], args);
    va_end(args);
}

/**
 * This runs in a separate thread and waits for incoming messages,
 * consumes them and stores them in the database
 */

- (void) listen {
    while (!stopListener) {
        @try {
            // This opens connection and channel
            if (![connMngr connectionIsAlive]) {
                [connMngr initializeConnection];
                // wait until the connection has revived
                continue;
            }
            
            // Declare the device queue
            long deviceName = [deviceManager localDeviceName];
            NSData* devNameData = [NSData dataWithBytes:&deviceName length:sizeof(deviceName)];
            NSString* deviceQueueName = [self queueNameForKey:devNameData withPrefix:@"ibedevice-"];

//            [connMngr deleteQueue:deviceQueueName onChannel:kAMQPChannelIncoming];
            [connMngr declareQueue:deviceQueueName onChannel:kAMQPChannelIncoming passive:NO];
            //TODO: device_queue_name needs to involve the identities some how? or be a larger byte array
            
            // Declare queues for each identity
            for (MIdentity* me in [identityManager ownedIdentities]) {
                IBEncryptionIdentity* ident = [identityManager ibEncryptionIdentityForIdentity:me forTemporalFrame:0];
                NSString* identityExchangeName = [self queueNameForKey:ident.key withPrefix:@"ibeidentity-"];
                
                //[self log:@"Declaring exchange %@ => %@", identityExchangeName, deviceQueueName];
                [connMngr declareExchange:identityExchangeName onChannel:kAMQPChannelIncoming passive:NO];                
                [connMngr bindQueue:deviceQueueName toExchange:identityExchangeName onChannel:kAMQPChannelIncoming];
                
                // If the initial queue exists, get its messages and remove it
                NSString* initialQueueName = [NSString stringWithFormat:@"initial-%@", identityExchangeName];
                
                int probe = [connMngr createChannel];
                @try {
                    [connMngr declareQueue:initialQueueName onChannel:probe passive:YES];
                    
                    int probe2 = [connMngr createChannel];
                    @try {
                        [connMngr unbindQueue:initialQueueName fromExchange:identityExchangeName onChannel:probe2];                    
                    } @catch (NSException *exception) {
                        [self log:@"Initial queue was not bound, ok"];
                    } @finally {
                        [connMngr closeChannel:probe2];
                    }
                    
                    // consume the initial messages
                    [connMngr consumeFromQueue:initialQueueName onChannel:kAMQPChannelIncoming];
//                    [self consumeMessagesFromQueue: initialQueueName perpetually:NO];
                }
                @catch (NSException *exception) {
                    [self log:@"Initial queue did not exist, ok"];
                }
                @finally {
                    [connMngr closeChannel:probe];
                }
            }
            
            [connMngr consumeFromQueue:deviceQueueName onChannel:kAMQPChannelIncoming];
            [self consumeMessagesFromQueue: nil perpetually:YES];
        }
        @catch (NSException *exception) {
            [self log:@"Crashed in listen %@", exception];
            [connMngr closeConnection];
        }
        
        [NSThread sleepForTimeInterval:0.5];
    }
    
    [connMngr closeConnection];
    [self log:@"Listener is done"];
}

- (void) consumeMessagesFromQueue: (NSString*) queue perpetually: (BOOL) perpetual  {
    //[connMngr consumeFromQueue:queue onChannel:kAMQPChannelIncoming];
    
    while (!stopListener) {
        [self log:@"Listening on %@", queue];
        NSData* body = [connMngr readMessage];
        
        if (body != nil) {
            MEncodedMessage* encoded = (MEncodedMessage*)[messageManager create];
            [encoded setEncoded: body];

            
            [self log:@"Incoming: %@", body];
            
            [connMngr ackMessage:[connMngr lastIncomingSequenceNumber] onChannel: kAMQPChannelIncoming];
        } else if (!perpetual) {
            break;
        }
        
        [NSThread sleepForTimeInterval:0.1];
    }
}


/**
 * This runs in a separate thread and waits for
 * messages ready to be sent, and then sends them
 */

- (void) send {
    // Perpetually wait for messages to become available
    while (!stopSender) {
        
        if (![connMgrOut connectionIsAlive]){
            [connMgrOut initializeConnection];
            // wait until the connection has revived
            continue;
        }
        [self log:@"Sending"];
        
        @try {
            NSArray* unsent = [[transportDataProvider store] unsentOutboundMessages];
            
            if (unsent != nil) {
                if ([unsent count] > 0)
                    [self log:@"Sending %d messages", [unsent count]];
                
                for (MEncodedMessage* msg in unsent) {
                    [self sendMessage: msg];
                }
            }
        } @catch (NSException* exception) {
            [self log:@"Crashed in send: %@", exception];
            // Failed to send message, close connection
            [connMgrOut closeConnection];
        } @finally {
        }
        
        // sleep 100 ms
        [NSThread sleepForTimeInterval:0.5];
    }
    
    [connMgrOut closeConnection];
    [self log:@"Sender is done"];
}

- (void) sendMessage: (MEncodedMessage*) msg {
    Message* m = [BSONEncoder decodeMessage:msg.encoded];
    
    NSMutableArray* ids = [NSMutableArray arrayWithCapacity:[m.r count]];
    NSMutableArray* hidForQueue = [NSMutableArray arrayWithCapacity:[m.r count]];
    
    for (int i=0; i<m.r.count; i++) {
        IBEncryptionIdentity* ident = [[[[IBEncryptionIdentity alloc] initWithKey:((Recipient*)[m.r objectAtIndex:i]).i] autorelease] keyAtTemporalFrame:0];
        [hidForQueue addObject: ident];
        
        MIdentity* mIdent = [[transportDataProvider store] createIdentity];
        [mIdent setPrincipalHash:[ident hashed]];
        [mIdent setType: [ident authority]];
        [ids addObject:mIdent];
    }
    
    NSData* groupExchangeNameBytes = [FeedManager fixedIdentifierForIdentities: ids];
    NSString* groupExchangeName = [self queueNameForKey:groupExchangeNameBytes withPrefix:@"ibegroup-"];
    
    
    if (![declaredGroups containsObject:groupExchangeName]) {
        [connMgrOut declareExchange:groupExchangeName onChannel:kAMQPChannelOutgoing passive:NO];
        //[self log:@"Creating group exchange: %@", groupExchangeName];
        
        for (IBEncryptionIdentity* recipient in hidForQueue) {
            NSString* dest = [self queueNameForKey:recipient.key withPrefix:@"ibeidentity-"];
            
            int probe = [connMgrOut createChannel];
            @try {
                // This will fail if the exchange doesn't exist
                [connMgrOut declareExchange:dest onChannel:probe passive:YES];
            } @catch (NSException *exception) {
                [self log:@"Identity change was not bound, define initial queue"];
                
                NSString* initialQueueName = [NSString stringWithFormat:@"initial-%@", dest];
                [connMgrOut declareQueue:initialQueueName onChannel:kAMQPChannelOutgoing passive:NO];
                [connMgrOut declareExchange:dest onChannel:kAMQPChannelOutgoing passive:NO];
                [connMgrOut bindQueue:initialQueueName toExchange:dest onChannel:kAMQPChannelOutgoing];
            } @finally {
                [connMngr closeChannel:probe];
            }
            
            //[self log:@"Binding exchange %@ <= exchange %@", dest, groupExchangeName];
            [connMgrOut bindExchange:dest to:groupExchangeName onChannel:kAMQPChannelOutgoing];
        }
    }
    
    //[self log:@"Publishing to %@", groupExchangeName];
    
    uint32_t deliveryTag = [connMgrOut nextSequenceNumber];
    [connMgrOut publish:msg.encoded to:groupExchangeName onChannel:kAMQPChannelOutgoing];
    
    [self log:@"Outgoing: %@", msg.encoded];
    
    [waitingForAck setObject:msg forKey:[NSNumber numberWithInt:deliveryTag]];
    
    // TODO: wait for ack;
    [self confirmDelivery:deliveryTag succeeded:YES];
}

- (void)confirmDelivery:(uint32_t)deliveryTag succeeded:(BOOL)ack {
    
    NSNumber* key = [NSNumber numberWithInt:deliveryTag];
    
    if (ack) {
        MEncodedMessage* msg = [waitingForAck objectForKey:key];
        assert (msg.outbound);
        
        msg.processed = YES;
        //[[[transportDataProvider store] context] save:NULL];
    } else {
        //don't immediately try to resend, just flag it, it will be rescanned later
        //this probably only happens if the server is temporarily out of space
    }
        
    [waitingForAck removeObjectForKey:key];
}

@end