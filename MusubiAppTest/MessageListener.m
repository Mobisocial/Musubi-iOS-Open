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
//  MessageListener.m
//  Musubi
//
//  Created by Willem Bult on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MessageListener.h"
#import "UserKeyManager.h"
#import "EncryptionUserKeyManager.h"
#import "EncodedMessageManager.h"

@implementation MessageListener

@synthesize identityProvider, identity, transportManager, transport;

- (id)initWithIdentityProvider:(UnverifiedIdentityProvider *)ip andIdentity:(IBEncryptionIdentity *)i {
    self = [super init];
    if (self != nil) {
        [self setIdentityProvider: ip];
        [self setIdentity: i];
        
        // Create a new store coordinator
        NSURL* storePath = [PersistentModelStore pathForStoreWithName:@"TestStore2"];
        [[NSFileManager defaultManager] removeItemAtPath:storePath.path error:NULL];
        
        NSPersistentStoreCoordinator* storeCoordinator = [PersistentModelStore coordinatorWithName:@"TestStore2"];
        
        transportManager = [[TransportManager alloc] initWithStore:[[PersistentModelStore alloc] initWithCoordinator:storeCoordinator] encryptionScheme:ip.encryptionScheme signatureScheme:ip.signatureScheme deviceName:random()];
        
        
        // Store our identity, device and signature key
        
        MIdentity* mIdent0 = [transportManager addClaimedIdentity: identity];
        [mIdent0 setOwned:YES];
        [mIdent0 setPrincipal: [i principal]];
        
        //MDevice* dev = [store newDevice];
        //[dev setDeviceName:transport.deviceName];
        
        IBEncryptionIdentity* requiredKey = [i keyAtTemporalFrame: [transportManager signatureTimeFrom:mIdent0]];
        MSignatureUserKey* sigKey = (MSignatureUserKey*)[transportManager.store createEntity: @"SignatureUserKey"];
        [sigKey setIdentity: mIdent0];
        [sigKey setKey: [identityProvider signatureKeyForIdentity:requiredKey].raw];
        [sigKey setPeriod: requiredKey.temporalFrame];
        [transportManager.store save];

        // Start the transport
        [self setTransport: [[AMQPTransport alloc] initWithStoreCoordinator:transportManager.store.context.persistentStoreCoordinator encryptionScheme:identityProvider.encryptionScheme signatureScheme:identityProvider.signatureScheme deviceName:transportManager.deviceName]];
        [self.transport start];
    }
    return self;
}

- (MEncodedMessage*) waitForMessage:(int)seq during:(NSTimeInterval)interval {
    EncodedMessageManager* emm = [[EncodedMessageManager alloc] initWithStore:[transportManager store]];
    NSDate* start = [NSDate date];
    
    while ([[NSDate date] timeIntervalSinceDate:start] < interval) {
//        MEncodedMessage* res = [emm lookupById: seq];
        NSArray* res = [emm query:nil];
        if (res != nil && res.count > seq) {
            return [res objectAtIndex: seq];
        }
        [NSThread sleepForTimeInterval:1];
    }
    return nil;
}

- (void) stop {
    [transport stop];
}
@end
