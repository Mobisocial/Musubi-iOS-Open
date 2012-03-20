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
//  Created by Willem Bult on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AMQPListener.h"
#import "UserKeyManager.h"
#import "EncryptionUserKeyManager.h"

@implementation AMQPListener

@synthesize identityProvider, identity, transportManager, transport;

- (id)initWithIdentityProvider:(UnverifiedIdentityProvider *)ip andIdentity:(IBEncryptionIdentity *)i {
    self = [super init];
    if (self != nil) {
        [self setIdentityProvider: ip];
        [self setIdentity: i];
        
        PersistentModelStore* store = [[PersistentModelStore alloc] initWithCoordinator:[PersistentModelStore coordinatorWithName:@"TestStore2"]];
        
        [self setTransportManager: [[TransportManager alloc] initWithStore: store encryptionScheme:[ip encryptionScheme] signatureScheme:[ip signatureScheme] deviceName:random()]];
        
        MIdentity* mIdent0 = [transportManager addClaimedIdentity: identity];
        [mIdent0 setOwned:YES];
        [mIdent0 setPrincipal: [i principal]];
        //[[store context] save:NULL];
        
        //MDevice* dev = [store newDevice];
        //[dev setDeviceName:random()];

        //EncryptionUserKeyManager* eukm = [[EncryptionUserKeyManager alloc] initWithStore:store encryptionScheme:[ip encryptionScheme]];
        UserKeyManager* sukm = [[UserKeyManager alloc] initWithStore:store encryptionScheme:[ip encryptionScheme] signatureScheme:[ip signatureScheme]];
        
        IBEncryptionIdentity* requiredKey = [i keyAtTemporalFrame: [transportManager signatureTimeFrom:mIdent0]];
        
        MSignatureUserKey* sigKey = (MSignatureUserKey*)[sukm create];
        [sigKey setIdentity: mIdent0];
        [sigKey setKey: [identityProvider signatureKeyForIdentity:requiredKey].raw];
        [sigKey setPeriod: requiredKey.temporalFrame];
        //[[store context] save:NULL];
                
        [self setTransport: [[AMQPTransport alloc] initWithTransportDataProvider:transportManager]];
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
        NSLog(@"Still waiting for message");
        [NSThread sleepForTimeInterval:1];
    }
    return nil;
}

- (void) stop {
    [transport stop];
}
@end
