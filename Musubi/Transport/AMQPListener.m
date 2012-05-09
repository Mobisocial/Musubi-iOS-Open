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

@implementation AMQPListener

@synthesize deviceManager,identityManager;

- (void) main {
    // Run AMQPThread common
    [super main];
    self.deviceManager = [[MusubiDeviceManager alloc] initWithStore:threadStore];
    self.identityManager = [[IdentityManager alloc] initWithStore:threadStore];
    
    while (![[NSThread currentThread] isCancelled]) {
        restartRequested = NO;
        
        @try {
            // This opens connection and channel
            if (![connMngr connectionIsAlive]) {
                [connMngr initializeConnection];
                // wait until the connection has revived
                continue;
            }
            
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
                    
                    // Consume the initial identity messages
                    [connMngr consumeFromQueue:initialQueueName onChannel:probe nolocal:YES exclusive:YES];
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
            
            //now that we are all set up, go ahead and update the push server... ideally we would do this less often, but for now, we'll do it here.
            
            NSMutableArray* idents = [[NSMutableArray alloc] init];
            for (MIdentity* me in [identityManager ownedIdentities]) {
                IBEncryptionIdentity* ident = [identityManager ibEncryptionIdentityForIdentity:me forTemporalFrame:0];
                NSString* identityExchangeName = [self queueNameForKey:ident.key withPrefix:@"ibeidentity-"];
                [idents addObject:identityExchangeName];
            }
            //TODO: this is racy with the remote registration request in app on init
            NSString* deviceToken = [Musubi sharedInstance].apnDeviceToken;
            
            if(deviceToken) {
                NSMutableDictionary* registrationRequest = [[NSMutableDictionary alloc] init];
                [registrationRequest setValue:idents forKey:@"identityExchanges"];
                [registrationRequest setValue:deviceToken forKey:@"deviceToken"];
                NSError* error = nil;
                NSData* body = [NSJSONSerialization dataWithJSONObject:registrationRequest options:0 error:&error];
                if(!body) {
                    NSLog(@"Failed to serialize json for registration %@", error);
                } else {
                    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                    [request setURL:[NSURL URLWithString:@"http://bumblebee.musubi.us:6253/api/0/register"]];
                    [request setHTTPMethod:@"POST"];
                    [request setValue:[NSString stringWithFormat:@"%u", body.length] forHTTPHeaderField:@"Content-Length"];
                    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                    [request setHTTPBody:body];
                    NSURLResponse* response;
                    NSError* error = nil;
                    
                    //Capturing server response
                    NSData* result = [NSURLConnection sendSynchronousRequest:request  returningResponse:&response error:&error];
                    
                    if(result) {
                        NSLog(@"Registration returned %@", result);
                    }
                }
            }
            [self consumeMessages];
        }
        @catch (NSException *exception) {
            [self log:@"Crashed in listen %@", exception];
            [connMngr closeConnection];
        }
        
        [NSThread sleepForTimeInterval:0.5];
    }
    
    [connMngr closeConnection];
}

- (void) consumeMessages {
    while (![[NSThread currentThread] isCancelled] && !restartRequested) {
        NSData* body = [connMngr readMessage];
        
        if (body != nil) {
            MEncodedMessage* encoded = (MEncodedMessage*)[threadStore createEntity:@"EncodedMessage"];
            encoded.encoded = body;
            encoded.processed = NO;
            encoded.outbound = NO;
            [threadStore save];
            
            [self log:@"Incoming: %@", body.sha256Digest];
            [self log:@"Incoming: %@", encoded.objectID];
            
            [[Musubi sharedInstance].notificationCenter postNotification: [NSNotification notificationWithName:kMusubiNotificationEncodedMessageReceived object:nil]];
            [connMngr ackMessage:[connMngr lastIncomingSequenceNumber] onChannel: kAMQPChannelIncoming];
        }
        
        [NSThread sleepForTimeInterval:0.1];
    }
}

- (void)restart {
    NSLog(@"AMQPListener: restarting");
    restartRequested = YES;
}


@end
