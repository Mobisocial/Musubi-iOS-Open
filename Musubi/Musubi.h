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
//  Musubi.h
//  musubi
//
//  Created by Willem Bult on 10/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IdentityProvider.h"

static NSString* kMusubiAppId = @"edu.stanford.mobisocial.dungbeetle";

#define kMusubiNotificationOwnedIdentityAvailable @"OwnedIdentityAvailable"
#define kMusubiNotificationAuthTokenRefresh @"AuthTokenRefresh"
#define kMusubiNotificationFacebookFriendRefresh @"FacebookFriendRefresh"
#define kMusubiNotificationMyProfileUpdate @"MyProfileUpdated"
#define kMusubiNotificationEncodedMessageReceived @"EncodedMessageReceived"
#define kMusubiNotificationPreparedEncoded @"EncodedMessagePrepared"
#define kMusubiNotificationPlainObjReady @"PlainObjReady"
#define kMusubiNotificationAppObjReady @"AppObjRead"
#define kMusubiNotificationUpdatedFeed @"UpdatedFeed"

#define kMusubiExceptionDuplicateMessage @"DuplicateMessage"
#define kMusubiExceptionRecipientMismatch @"RecipientMismatch"
#define kMusubiExceptionSenderBlacklisted @"SenderBlacklisted"
#define kMusubiExceptionMessageCorrupted @"MessageCorrupted"
#define kMusubiExceptionBadSignature @"BadSignature"
#define kMusubiExceptionNeedEncryptionUserKey @"NeedEncryptionUserKey"
#define kMusubiExceptionNeedSignatureUserKey @"NeedSignatureUserKey"
#define kMusubiExceptionInvalidAccountType @"InvalidAccountType"
#define kMusubiExceptionNotFound @"NotFound"
#define kMusubiExceptionInvalidRequest @"InvalidRequest"
#define kMusubiExceptionFeedWithoutOwnedIdentity @"NoOwnedIdentityInFeed"
#define kMusubiExceptionAppNotAllowedInFeed @"AppNotAllowedInFeed"
#define kMusubiExceptionMessageTooLarge @"MessageTooLarge"
#define kMusubiExceptionBadObjFormat @"BadObjFormat"
#define kMusubiExceptionUnexpected @"Unexpected"

@class PersistentModelStore, PersistentModelStoreFactory, IdentityKeyManager, MessageEncodeService, MessageDecodeService, AMQPTransport;


@interface Musubi : NSObject {
    PersistentModelStore* mainStore; 
    PersistentModelStoreFactory* storeFactory;

    NSNotificationCenter* notificationCenter;

    id<IdentityProvider> identityProvider;
    IdentityKeyManager* keyManager;
    MessageEncodeService* encodeService;
    MessageDecodeService* decodeService;
    AMQPTransport* transport;
}

// store to use on the main thread
@property (nonatomic, retain) PersistentModelStore* mainStore;
@property (nonatomic, retain) PersistentModelStoreFactory* storeFactory;

@property (nonatomic, retain) NSNotificationCenter* notificationCenter;

@property (nonatomic, retain) AMQPTransport* transport;
@property (nonatomic, retain) IdentityKeyManager* keyManager;
@property (nonatomic, retain) MessageEncodeService* encodeService;
@property (nonatomic, retain) MessageDecodeService* decodeService;


+ (Musubi*) sharedInstance;

// creates a new store on the current thread
- (PersistentModelStore*) newStore;

@end
