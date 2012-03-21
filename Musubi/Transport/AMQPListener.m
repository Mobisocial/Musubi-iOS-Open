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
//  AMQPListener.m
//  Musubi
//
//  Created by Willem Bult on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AMQPListener.h"

@implementation AMQPListener

@synthesize deviceManager;

- (void) main {
    // Run AMQPThread common
    [super main];
    [self setDeviceManager:[[DeviceManager alloc] initWithStore:transportDataProvider.store]];
    
    while (![[NSThread currentThread] isCancelled]) {
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
            for (MIdentity* me in [[transportDataProvider identityManager] ownedIdentities]) {
                IBEncryptionIdentity* ident = [[transportDataProvider identityManager] ibEncryptionIdentityForIdentity:me forTemporalFrame:0];
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
            [self consumeMessagesFromQueue: nil];
        }
        @catch (NSException *exception) {
            [self log:@"Crashed in listen %@", exception];
            [connMngr closeConnection];
        }
        
        [NSThread sleepForTimeInterval:0.5];
    }
    
    [connMngr closeConnection];
}

- (void) consumeMessagesFromQueue: (NSString*) queue {
    //[connMngr consumeFromQueue:queue onChannel:kAMQPChannelIncoming];
    
    while (![[NSThread currentThread] isCancelled]) {
        NSData* body = [connMngr readMessage];
        
        if (body != nil) {
            MEncodedMessage* encoded = [[transportDataProvider store] createEncodedMessage];
            [encoded setEncoded: body];
            [transportDataProvider.store save];
            
            [self log:@"Incoming: %@", body];
            
            [connMngr ackMessage:[connMngr lastIncomingSequenceNumber] onChannel: kAMQPChannelIncoming];
        }
        
        [NSThread sleepForTimeInterval:0.1];
    }
}


@end
