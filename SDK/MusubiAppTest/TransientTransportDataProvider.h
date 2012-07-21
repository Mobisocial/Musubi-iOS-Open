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
//  TransientTransportDataProvider.h
//  Musubi
//
//  Created by Willem Bult on 2/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TransportDataProvider.h"
#import "PersistentModelStore.h"
#import "Musubi.h"

@protocol BlackListProvider
- (BOOL) isBlackListed: (IBEncryptionIdentity*) identity;
@end

@interface DefaultBlackListProvider : NSObject<BlackListProvider>
@end

@protocol SignatureController
- (uint64_t) signingTimeForIdentity: (IBEncryptionIdentity*) hid;
- (BOOL) hasSignatureKey: (IBEncryptionIdentity*) hid;
@end

@interface DefaultSignatureController : NSObject<SignatureController>
@end

@protocol EncryptionController
- (uint64_t) encryptionTimeForIdentity: (IBEncryptionIdentity*) hid;
- (BOOL) hasEncryptionKey: (IBEncryptionIdentity*) hid;
@end

@interface DefaultEncryptionController : NSObject<EncryptionController>
@end

@interface TransientTransportDataProvider : NSObject<TransportDataProvider> 

@property (nonatomic, strong) id<BlackListProvider> blacklistProvider;
@property (nonatomic, strong) id<SignatureController> signatureController;
@property (nonatomic, strong) id<EncryptionController> encryptionController;

@property (nonatomic, strong) PersistentModelStore* store;

@property (nonatomic, strong) IBEncryptionScheme* encryptionScheme;
@property (nonatomic, strong) IBSignatureScheme* signatureScheme;
@property (nonatomic, strong) IBEncryptionIdentity* myIdentity;

@property (nonatomic, assign) uint64_t deviceName;

@property (nonatomic, strong) NSMutableDictionary* identities;
@property (nonatomic, strong) NSMutableDictionary* identityLookup;
@property (nonatomic, strong) NSMutableDictionary* devices;
@property (nonatomic, strong) NSMutableDictionary* deviceLookup;
@property (nonatomic, strong) NSMutableDictionary* encodedMessages;
@property (nonatomic, strong) NSMutableDictionary* encodedMessageLookup;
@property (nonatomic, strong) NSMutableDictionary* incomingSecrets;
@property (nonatomic, strong) NSMutableDictionary* outgoingSecrets;
@property (nonatomic, strong) NSMutableDictionary* missingSequenceNumbers;

- (id) initWithEncryptionScheme: (IBEncryptionScheme*) es signatureScheme: (IBSignatureScheme*) ss identity: (IBEncryptionIdentity*) me blacklistProvicer: (id<BlackListProvider>) blacklist signatureController: (id<SignatureController>) signatureController encryptionController: (id<EncryptionController>) encryptionController;
- (MEncodedMessage*) insertEncodedMessageData: (NSData*) data;



@end
