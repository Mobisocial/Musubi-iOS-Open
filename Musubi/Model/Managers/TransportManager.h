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
//  TransportManager.h
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TransportDataProvider.h"

@class PersistentModelStore, IBEncryptionScheme, IBSignatureScheme;
@class IdentityManager, EncryptionUserKeyManager, SignatureUserKeyManager;

@interface TransportManager : NSObject<TransportDataProvider> {
    PersistentModelStore* store;
    IBEncryptionScheme* encryptionScheme;
    IBSignatureScheme* signatureScheme;
    uint64_t deviceName;

    IdentityManager* identityManager;
    EncryptionUserKeyManager* encryptionUserKeyManager;
    SignatureUserKeyManager* signatureUserKeyManager;
}

@property (nonatomic) PersistentModelStore* store;
@property (nonatomic) IBEncryptionScheme* encryptionScheme;
@property (nonatomic) IBSignatureScheme* signatureScheme;
@property (nonatomic, assign) uint64_t deviceName;
@property (nonatomic) IdentityManager* identityManager;
@property (nonatomic) EncryptionUserKeyManager* encryptionUserKeyManager;
@property (nonatomic) SignatureUserKeyManager* signatureUserKeyManager;

- (id) initWithStore: (PersistentModelStore*) store encryptionScheme: (IBEncryptionScheme*) es signatureScheme: (IBSignatureScheme*) ss deviceName: (uint64_t) devName;

@end
