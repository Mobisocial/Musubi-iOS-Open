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
//  IdentityKeyManager.h
//  Musubi
//
//  Created by Willem Bult on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IdentityProvider.h"

@class IBEncryptionIdentity, PersistentModelStore, IdentityManager, IdentityKeyManager, EncryptionUserKeyManager, SignatureUserKeyManager;

@interface IdentityKeyManager : NSObject {
    NSMutableArray* requestedEncryptionKeys;
    NSMutableArray* requestedSignatureKeys;
    
    NSMutableDictionary* encryptionBackoff;
    NSMutableDictionary* signatureBackoff;
    
    id<IdentityProvider> identityProvider;
}

@property (atomic, retain) NSMutableArray* requestedEncryptionKeys;
@property (atomic, retain) NSMutableArray* requestedSignatureKeys;
@property (atomic, retain) NSMutableDictionary* encryptionBackoff;
@property (atomic, retain) NSMutableDictionary* signatureBackoff;
@property (atomic, retain) id<IdentityProvider> identityProvider;

- (id) initWithIdentityProvider: (id<IdentityProvider>) idp;
- (long) updateBackoffForIdentity: (IBEncryptionIdentity*) hid inMap: (NSMutableDictionary*) map;

@end

@interface IdentityKeyRefreshOperation : NSOperation {
    PersistentModelStore* store;
    
    IdentityKeyManager* manager;
    
    IdentityManager* identityManager;
    EncryptionUserKeyManager* encryptionUserKeyManager;
    SignatureUserKeyManager* signatureUserKeyManager;
}

@property (nonatomic, retain) PersistentModelStore* store;
@property (nonatomic, retain) IdentityKeyManager* manager;

@property (nonatomic, retain) IdentityManager* identityManager;

@property (nonatomic, retain) EncryptionUserKeyManager* encryptionUserKeyManager;
@property (nonatomic, retain) SignatureUserKeyManager* signatureUserKeyManager;

- (id) initWithManager: (IdentityKeyManager*) manager;

@end
