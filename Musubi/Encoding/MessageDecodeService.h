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
//  MessageDecodeService.h
//  Musubi
//
//  Created by Willem Bult on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "IdentityProvider.h"

@class PersistentModelStoreFactory, PersistentModelStore;
@class FeedManager, DeviceManager, TransportManager, AccountManager, AppManager, IdentityManager;
@class MessageDecoder;

@interface MessageDecodeService : NSObject {
    //PersistentModelStore* store;
    PersistentModelStoreFactory* storeFactory;
    id<IdentityProvider> identityProvider;
    
    NSThread* thread;
    
    NSMutableArray* pending;
}

@property (nonatomic, retain) PersistentModelStoreFactory* storeFactory;
//@property (nonatomic, retain) PersistentModelStore* store;
@property (nonatomic, retain) id<IdentityProvider> identityProvider;

// List of operation threads
@property (nonatomic, retain) NSThread* thread;

// List of objs that are pending processing
@property (atomic, retain) NSMutableArray* pending;

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) sf andIdentityProvider: (id<IdentityProvider>) ip;


@end

@interface MessageDecodeThread : NSThread {
    MessageDecodeService* service;
    
    PersistentModelStore* store;
    DeviceManager* deviceManager;
    IdentityManager* identityManager;
    TransportManager* transportManager;
    FeedManager* feedManager;
    AccountManager* accountManager;
    AppManager* appManager;
    MessageDecoder* decoder;
    
    // id<IdentityProvider> identityProvider;
    //    NSOperationQueue* queue;
    NSMutableArray* queue;
}

@property (nonatomic, retain) MessageDecodeService* service;
//@property (nonatomic, retain) NSOperationQueue* queue;
@property (nonatomic, retain) NSMutableArray* queue;

@property (nonatomic, retain) MessageDecoder* decoder;
//@property (nonatomic, retain) id<IdentityProvider> identityProvider;

@property (nonatomic, retain) PersistentModelStore* store;
@property (nonatomic, retain) DeviceManager* deviceManager;
@property (nonatomic, retain) IdentityManager* identityManager;
@property (nonatomic, retain) TransportManager* transportManager;
@property (nonatomic, retain) FeedManager* feedManager;
@property (nonatomic, retain) AccountManager* accountManager;
@property (nonatomic, retain) AppManager* appManager;

- (id) initWithService: (MessageDecodeService*) service;

@end

@interface MessageDecodedNotifyOperation : NSOperation {
}

@end


@interface MessageDecodeOperation : NSOperation {
    // ManagedObject is not thread-safe, ObjectID is
    NSManagedObjectID* messageId;
    MessageDecodeThread* thread;
    NSMutableArray* dirtyFeeds;
    BOOL success;
}

@property (nonatomic, retain) NSManagedObjectID* messageId;
@property (nonatomic, retain) MessageDecodeThread* thread;
@property (nonatomic, retain) NSMutableArray* dirtyFeeds;
@property (nonatomic, assign) BOOL shouldRunProfilePush;
@property (nonatomic, assign) BOOL success;

- (id) initWithMessageId: (NSManagedObjectID*) msgId onThread: (MessageDecodeThread*) thread;

@end