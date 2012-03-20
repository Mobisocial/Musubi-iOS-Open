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

@protocol BlackListProvider
- (BOOL) isBlackListed: (IBEncryptionIdentity*) identity;
@end

@interface DefaultBlackListProvider : NSObject<BlackListProvider>
@end

@protocol SignatureController
- (long) signingTimeForIdentity: (IBEncryptionIdentity*) hid;
- (BOOL) hasSignatureKey: (IBEncryptionIdentity*) hid;
@end

@interface DefaultSignatureController : NSObject<SignatureController>
@end

@protocol EncryptionController
- (long) encryptionTimeForIdentity: (IBEncryptionIdentity*) hid;
- (BOOL) hasEncryptionKey: (IBEncryptionIdentity*) hid;
@end

@interface DefaultEncryptionController : NSObject<EncryptionController>
@end

@interface TransientTransportDataProvider : NSObject<TransportDataProvider> {
    id<BlackListProvider> blacklistProvider;
    id<SignatureController> signatureController;
    id<EncryptionController> encryptionController;
    
    PersistentModelStore* store;
    
    IBEncryptionScheme* encryptionScheme;
    IBSignatureScheme* signatureScheme;
    IBEncryptionIdentity* myIdentity;
    
    long deviceName;
    
    NSMutableDictionary* identities;
    NSMutableDictionary* identityLookup;
    
    NSMutableDictionary* devices;
    NSMutableDictionary* deviceLookup;
    
    NSMutableDictionary* encodedMessages;
    NSMutableDictionary* encodedMessageLookup;

    NSMutableDictionary* incomingSecrets;
    NSMutableDictionary* outgoingSecrets;
    
    NSMutableDictionary* missingSequenceNumbers;
}

@property (nonatomic, retain) id<BlackListProvider> blacklistProvider;
@property (nonatomic, retain) id<SignatureController> signatureController;
@property (nonatomic, retain) id<EncryptionController> encryptionController;

@property (nonatomic, retain) PersistentModelStore* store;

@property (nonatomic, retain) IBEncryptionScheme* encryptionScheme;
@property (nonatomic, retain) IBSignatureScheme* signatureScheme;
@property (nonatomic, retain) IBEncryptionIdentity* myIdentity;

@property (nonatomic, assign) long deviceName;

@property (nonatomic, retain) NSMutableDictionary* identities;
@property (nonatomic, retain) NSMutableDictionary* identityLookup;
@property (nonatomic, retain) NSMutableDictionary* devices;
@property (nonatomic, retain) NSMutableDictionary* deviceLookup;
@property (nonatomic, retain) NSMutableDictionary* encodedMessages;
@property (nonatomic, retain) NSMutableDictionary* encodedMessageLookup;
@property (nonatomic, retain) NSMutableDictionary* incomingSecrets;
@property (nonatomic, retain) NSMutableDictionary* outgoingSecrets;
@property (nonatomic, retain) NSMutableDictionary* missingSequenceNumbers;

- (id) initWithEncryptionScheme: (IBEncryptionScheme*) es signatureScheme: (IBSignatureScheme*) ss identity: (IBEncryptionIdentity*) me blacklistProvicer: (id<BlackListProvider>) blacklist signatureController: (id<SignatureController>) signatureController encryptionController: (id<EncryptionController>) encryptionController;
- (MEncodedMessage*) insertEncodedMessageData: (NSData*) data;



@end
