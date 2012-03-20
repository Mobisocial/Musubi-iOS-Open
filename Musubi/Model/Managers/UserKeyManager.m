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
//  UserKeyManager.m
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UserKeyManager.h"

@implementation UserKeyManager

@synthesize signatureScheme;

- (id)initWithStore:(PersistentModelStore *)s encryptionScheme:(IBEncryptionScheme *)es signatureScheme:(IBSignatureScheme *)ss {
    self = [super initWithEntityName:@"SignatureUserKey" andStore:s];
    
    if (self != nil) {
        [self setSignatureScheme: ss];
    }
    
    return self;
}

- (void)createSignatureUserKey:(MSignatureUserKey *)signatureKey {
	// TODO: synchronize code
    [[store context] save:NULL];
}

- (IBEncryptionUserKey *)signatureKeyFrom:(MIdentity *)from to:(IBEncryptionIdentity *)to {
    NSArray* results = [self query:[NSPredicate predicateWithFormat:@"identity = %@ AND period = %ld", from, to.temporalFrame]];
    
    for (int i=0; i<results.count; i++) {
        return [[[IBEncryptionUserKey alloc] initWithRaw: ((MSignatureUserKey*)[results objectAtIndex:i]).key] autorelease];
    }
    return nil;
}

- (void)updateSignatureUserKey:(MSignatureUserKey *)signatureKey {
    
}

@end
