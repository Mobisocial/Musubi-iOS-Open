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
#import "Musubi.h"
#import "AMQPConnectionManager.h"
#import "MusubiDeviceManager.h"
#import "IdentityManager.h"
#import "MEncodedMessage.h"
#import "IBEncryptionScheme.h"
#import "PersistentModelStore.h"
#import "APNPushManager.h"

@implementation AMQPListener 


@synthesize backgroundTaskId;

- (void) main {
    // Run AMQPThread common
    [super main];
    
    while (![[NSThread currentThread] isCancelled]) {
        restartRequested = NO;

        PersistentModelStore* store = [storeFactory newStore];
        IdentityManager* identityManager = [[IdentityManager alloc] initWithStore:store];
        MusubiDeviceManager* deviceManager = [[MusubiDeviceManager alloc] initWithStore:store];

        @try {                        
            // This opens connection and channel
            if (![connMngr connectionIsAlive]) {
                [connMngr initializeConnection];
                // wait until the connection has revived
                continue;
            }

            @synchronized(self.connMngr.connLock) {
                
                // Declare the device queue
                uint64_t deviceName = [deviceManager localDeviceName];
                NSData* devNameData = [NSData dataWithBytes:&deviceName length:sizeof(deviceName)];
                NSString* deviceQueueName = [self queueNameForKey:devNameData withPrefix:@"ibedevice-"];
                
                [connMngr declareQueue:deviceQueueName onChannel:kAMQPChannelIncoming passive:NO durable:YES exclusive:NO];
                //TODO: device_queue_name needs to involve the identities some how? or be a larger byte array
                
                
                // Declare queues for each identity
                for (MIdentity* me in [identityManager ownedIdentities]) {
                    IBEncryptionIdentity* ident = [identityManager ibEncryptionIdentityForIdentity:me forTemporalFrame:0];
                    NSString* identityExchangeName = [self queueNameForKey:ident.key withPrefix:@"ibeidentity-"];
                    NSLog(@"Listening on %@", identityExchangeName);
                    
                    //[self log:@"Declaring exchange %@ => %@", identityExchangeName, deviceQueueName];
                    [connMngr declareExchange:identityExchangeName onChannel:kAMQPChannelIncoming passive:NO durable:YES];                
                    [connMngr bindQueue:deviceQueueName toExchange:identityExchangeName onChannel:kAMQPChannelIncoming];
                    
                    // If the initial queue exists, get its messages and remove it
                    NSString* initialQueueName = [NSString stringWithFormat:@"initial-%@", identityExchangeName];

                    int probe = [connMngr createChannel];
                    @try {
                        [connMngr declareQueue:initialQueueName onChannel:probe passive:YES durable:YES exclusive:NO];
                        
                        int probe2 = [connMngr createChannel];
                        @try {
                            [connMngr unbindQueue:initialQueueName fromExchange:identityExchangeName onChannel:probe2];                    
                        } @catch (NSException *exception) {
                            [self log:@"Initial queue was not bound, ok"];
                        } @finally {
                            [connMngr closeChannel:probe2];
                        }
                        
                        // Consume the initial identity messages, non-exclusive
                        [connMngr consumeFromQueue:initialQueueName onChannel:probe nolocal:YES exclusive:NO];
                    }
                    @catch (NSException *exception) {
                        [self log:@"Exception: %@", exception];
                        [self log:@"Initial queue did not exist, ok"];
                        [connMngr closeChannel:probe];
                    }
                    @finally {
                    }

                }
                // Consume from the device queue
                [connMngr consumeFromQueue:deviceQueueName onChannel:kAMQPChannelIncoming nolocal:YES exclusive:YES];
                self.connMngr.connectionState = @"Connected";
            }
            //now that we are all set up, go ahead and update the push server... ideally we would do this less often, but for now, we'll do it here.
            connMngr.connectionAttempts = 0;

            NSMutableArray* idents = [[NSMutableArray alloc] init];
            for (MIdentity* me in [identityManager ownedIdentities]) {
                IBEncryptionIdentity* ident = [identityManager ibEncryptionIdentityForIdentity:me forTemporalFrame:0];
                NSString* identityExchangeName = [self queueNameForKey:ident.key withPrefix:@"ibeidentity-"];
                [idents addObject:identityExchangeName];
            }
            NSString* deviceToken = [Musubi sharedInstance].apnDeviceToken;
            
            if(deviceToken) {
                [APNPushManager registerDevice:deviceToken identities:idents localUnread:[APNPushManager tallyLocalUnread]];
            }
            

            [self consumeMessages];
        }
        @catch (NSException *exception) {
            [self log:@"Crashed in listen %@", exception];
            [connMngr closeConnection];
        }
    }
    
    [connMngr closeConnection];
}


- (void) consumeMessages {
    UIApplication* application = [UIApplication sharedApplication];
    backgroundTaskId = [application beginBackgroundTaskWithExpirationHandler:^(void) {
        [connMngr closeConnection];
        restartRequested = YES;
        [application endBackgroundTask:backgroundTaskId];
        backgroundTaskId = ~0U;
    }];
    @try {
        __block BOOL need_reset = YES;
        __block NSDate* idleTime = [[NSDate date] dateByAddingTimeInterval:15];
        
        while (![[NSThread currentThread] isCancelled] && !restartRequested) {
            NSData* body = [connMngr readMessageAndCall:^{
                if(need_reset)
                    [APNPushManager resetBothUnreadInBackgroundTask];
                idleTime = [[NSDate date] dateByAddingTimeInterval:15]; //probably can make this 30
                need_reset = NO;
            } after:idleTime];
            
            //this may wake up unnecessarily, but that essentially means
            //the connection is idle or it switch from doing sends to receives
            //temporarily
            if (body == nil) {
                continue;
            }
            need_reset = NO;
            idleTime = [[NSDate date] dateByAddingTimeInterval:15];
            
            
            PersistentModelStore* store = [storeFactory newStore];
            MEncodedMessage* encoded = (MEncodedMessage*)[store createEntity:@"EncodedMessage"];
            encoded.encoded = body;
            encoded.processed = NO;
            encoded.outbound = NO;
            
            NSError* error = nil;
            if (![store.context obtainPermanentIDsForObjects:[NSArray arrayWithObject:encoded] error:&error]) {
                @throw error;
            }
            [store save];
            
            [self log:@"Incoming: %@", encoded.objectID];
            
            [[Musubi sharedInstance].notificationCenter postNotification: [NSNotification notificationWithName:kMusubiNotificationEncodedMessageReceived object:encoded.objectID]];
            [connMngr ackMessage:[connMngr lastIncomingSequenceNumber] onChannel: kAMQPChannelIncoming];
        }
    } 
    @finally {
        if(backgroundTaskId != ~0U) {
            [application endBackgroundTask:backgroundTaskId];
            backgroundTaskId = ~0U;
        }
    }
}

- (void)restart {
    NSLog(@"AMQPListener: restarting");
    restartRequested = YES;
}


@end
