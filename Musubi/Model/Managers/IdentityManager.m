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
//  IdentityManager.m
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IdentityManager.h"
#include <openssl/bn.h>

@implementation IdentityManager

- (id)initWithStore:(PersistentModelStore *)s {
    self = [super initWithEntityName:@"Identity" andStore:s];
    if (self != nil) {
    }
    return self;
}

- (void)updateIdentity:(MIdentity *)ident {
    
    assert(ident != nil);
    assert(ident.principalHash != nil && *(long*)ident.principalHash.bytes == ident.principalShortHash);
    
    // TOOD: synchronize code
    [ident setUpdatedAt: [[NSDate date] timeIntervalSince1970]];
    [[store context] save:NULL];
}

- (void) createIdentity:(MIdentity *)ident {
    assert(ident.principalHash != nil && *((long*)ident.principalHash.bytes) == ident.principalShortHash);
    
	// TOOD: synchronize code
    [ident setCreatedAt: [[NSDate date] timeIntervalSince1970]];
    [ident setUpdatedAt: [[NSDate date] timeIntervalSince1970]];
    
    [[store context] save:NULL];
}

- (NSArray *)ownedIdentities {
    return [self query:[NSPredicate predicateWithFormat:@"owned=1"]];
}

- (MIdentity *)identityForIBEncryptionIdentity:(IBEncryptionIdentity *)ident {
    NSArray* results = [self query: [NSPredicate predicateWithFormat:@"type = %d AND principalShortHash = %d", ident.authority, *(long*)[ident.hashed bytes]]];
    
    for (int i=0; i<results.count; i++) {
        MIdentity* match = [results objectAtIndex:i];
        if (![[match principalHash] isEqualToData:ident.hashed])
            return nil;
        return match;
    }
    return nil;
}

- (IBEncryptionIdentity *)ibEncryptionIdentityForIdentity:(MIdentity *)ident forTemporalFrame:(long) tf{
    return [[[IBEncryptionIdentity alloc] initWithAuthority:ident.type hashedKey:ident.principalHash temporalFrame:tf] autorelease];
}


- (long)computeTemporalFrameFromHash:(NSData *)hash {
    return 0;
}

- (void)incrementSequenceNumberTo:(MIdentity *)to {
    [to setNextSequenceNumber: to.nextSequenceNumber + 1];
}

@end
