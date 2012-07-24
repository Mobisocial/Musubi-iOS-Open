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
#define kMusubiNotificationAuthAccountValid @"AuthAccountValid"
#define kMusubiNotificationAuthAccountFailed @"AuthAccountFailed"
#define kMusubiNotificationFacebookFriendRefresh @"FacebookFriendRefresh"
#define kMusubiNotificationGoogleFriendRefresh @"GoogleFriendRefresh"
#define kMusubiNotificationAddressBookRefresh @"AddressBookRefresh"
#define kMusubiNotificationMyProfileUpdate @"MyProfileUpdated"
#define kMusubiNotificationObjSent @"ObjSent"
#define kMusubiNotificationEncodedMessageSent @"EncodedMessageSent"
#define kMusubiNotificationEncodedMessageReceived @"EncodedMessageReceived"
#define kMusubiNotificationPreparedEncoded @"EncodedMessagePrepared"
#define kMusubiNotificationPlainObjReady @"PlainObjReady"
#define kMusubiNotificationAppObjReady @"AppObjRead"
#define kMusubiNotificationMessageEncodeStarted @"MessageEncodeStarted"
#define kMusubiNotificationMessageDecodeStarted @"MessageDecodeStarted"
#define kMusubiNotificationMessageDecodeFinished @"MessageDecodeFinished"
#define kMusubiNotificationUpdatedFeed @"UpdatedFeed"
#define kMusubiNotificationIdentityImported @"IdentityImported"
#define kMusubiNotificationIdentityImportFinished @"IdentityImportFinished"
#define kMusubiNotificationConnectionStateChanged @"ConnectionStateChanged"

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

#define kMusubiThreadPriorityBackground 0.0

#define kMusubiUriScheme @"musubi"

@class PersistentModelStore, PersistentModelStoreFactory, IdentityKeyManager, MessageEncodeService, MessageDecodeService, AMQPTransport, ObjProcessorService, AddressBookIdentityManager, CorralHTTPServer, MObj, AphidIdentityProvider;


@interface Musubi : NSObject

// store to use on the main thread
@property (nonatomic, strong) PersistentModelStore* mainStore;
@property (nonatomic, strong) PersistentModelStoreFactory* storeFactory;

@property (nonatomic, strong) NSNotificationCenter* notificationCenter;

@property (nonatomic, strong) AphidIdentityProvider* identityProvider;

@property (nonatomic, strong) AMQPTransport* transport;
@property (nonatomic, strong) IdentityKeyManager* keyManager;
@property (nonatomic, strong) MessageEncodeService* encodeService;
@property (nonatomic, strong) MessageDecodeService* decodeService;
@property (nonatomic, strong) ObjProcessorService* objPipelineService;
//this is updated in the main thread for notifications, but it also 
//read from a background thread
@property (atomic, strong) NSString* apnDeviceToken;

@property (nonatomic, strong) AddressBookIdentityManager* addressBookIdentityUpdater;

@property (nonatomic, strong) CorralHTTPServer* corralHTTPServer;

+ (Musubi*) sharedInstance;
+ (NSString *)urlForObjRaw:(MObj *)obj;

// creates a new store on the current thread
- (PersistentModelStore*) newStore;

- (void) setTransportPrefix: (NSString*) prefix;
- (void) onAppLaunch;
- (void) onRemoteNotification:(NSDictionary *)userInfo;
- (void) onAppDidBecomeActive;
- (void) onAppWillResignActive;
- (BOOL) handleURL: (NSURL*) url fromSourceApplication: (NSString*) sourceApplication;
@end
