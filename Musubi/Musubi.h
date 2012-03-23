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
#import "IBEncryptionScheme.h"
#import "AMQPTransport.h"
#import "IdentityKeyManager.h"
#import "MessageEncodeService.h"

static NSString* kMusubiAppId = @"edu.stanford.mobisocial.dungbeetle";

#define kMusubiNotificationOwnedIdentityAvailable @"owned_identity_available"
#define kMusubiNotificationAuthTokenRefresh @"auth_token_refresh"
#define kMusubiNotificationMyProfileUpdate @"my_profile_update"
#define kMusubiNotificationEncodedMessageReceived @"encoded_message_received"
#define kMusubiNotificationPlainObjReady @"plain_obj_ready"
#define kMusubiNotificationPreparedEncoded @"prepared_encoded"
#define kMusubiNotificationAppObjReady @"app_obj_ready"

@interface Musubi : NSObject {
    PersistentModelStore* mainStore; 
    PersistentModelStoreFactory* storeFactory;

    NSNotificationCenter* notificationCenter;

    id<IdentityProvider> identityProvider;
    IdentityKeyManager* keyManager;
    MessageEncodeService* encodeService;
    AMQPTransport* transport;
}

// store to use on the main thread
@property (nonatomic, retain) PersistentModelStore* mainStore;
@property (nonatomic, retain) PersistentModelStoreFactory* storeFactory;

@property (nonatomic, retain) NSNotificationCenter* notificationCenter;

@property (nonatomic, retain) AMQPTransport* transport;
@property (nonatomic, retain) IdentityKeyManager* keyManager;
@property (nonatomic, retain) MessageEncodeService* encodeService;


+ (Musubi*) sharedInstance;

// creates a new store on the current thread
- (PersistentModelStore*) newStore;

@end
