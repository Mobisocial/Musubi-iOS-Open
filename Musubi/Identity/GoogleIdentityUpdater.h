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
//  GoogleIdentityUpdater.h
//  musubi
//
//  Created by Willem Bult on 3/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kGoogleIdentityUpdaterFrequency 14400.0

@class PersistentModelStoreFactory, PersistentModelStore, GoogleAuthManager, IBEncryptionIdentity, MIdentity;

@interface GoogleIdentityUpdater : NSObject {
    PersistentModelStoreFactory* _storeFactory;
    NSOperationQueue* queue;
}

@property (nonatomic) PersistentModelStoreFactory* storeFactory;
@property (nonatomic) NSOperationQueue* queue;

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) storeFactory;

@end


@interface GoogleIdentityFetchOperation : NSOperation<NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
    PersistentModelStoreFactory* _storeFactory;
    PersistentModelStore* _store;
    GoogleAuthManager* _authManager;
    
    BOOL _identityAdded;
    BOOL _profileDataChanged;
}

@property (nonatomic) PersistentModelStoreFactory* storeFactory;
@property (nonatomic) PersistentModelStore* store;
@property (nonatomic) GoogleAuthManager* authManager;

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) storeFactory;
- (MIdentity*) ensureIdentity: (long) fbId name: (NSString*) name andIdentity: (IBEncryptionIdentity*) ibeId;

@end