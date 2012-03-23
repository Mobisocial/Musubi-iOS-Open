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
//  MessageEncodeService.h
//  Musubi
//
//  Created by Willem Bult on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PersistentModelStore.h"
#import "IdentityProvider.h"
#import "MessageEncoder.h"
#import "IdentityManager.h"
#import "DeviceManager.h"
#import "TransportManager.h"

@interface MessageEncodeService : NSObject {
    //PersistentModelStore* store;
    PersistentModelStoreFactory* storeFactory;
    id<IdentityProvider> identityProvider;
    
    NSArray* threads;
    
    NSMutableArray* pending;
}

@property (nonatomic, retain) PersistentModelStoreFactory* storeFactory;
//@property (nonatomic, retain) PersistentModelStore* store;
@property (nonatomic, retain) id<IdentityProvider> identityProvider;

// List of operation threads
@property (nonatomic, retain) NSArray* threads;

// List of objs that are pending processing
@property (atomic, retain) NSMutableArray* pending;

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) sf andIdentityProvider: (id<IdentityProvider>) ip;

@end

@interface MessageEncodeThread : NSThread {
    MessageEncodeService* service;
    
    PersistentModelStore* store;
    DeviceManager* deviceManager;
    IdentityManager* identityManager;
    TransportManager* transportManager;
    MessageEncoder* encoder;
    
   // id<IdentityProvider> identityProvider;
//    NSOperationQueue* queue;
    NSMutableArray* queue;
}

@property (nonatomic, retain) MessageEncodeService* service;
//@property (nonatomic, retain) NSOperationQueue* queue;
@property (nonatomic, retain) NSMutableArray* queue;

@property (nonatomic, retain) MessageEncoder* encoder;
//@property (nonatomic, retain) id<IdentityProvider> identityProvider;

@property (nonatomic, retain) PersistentModelStore* store;
@property (nonatomic, retain) DeviceManager* deviceManager;
@property (nonatomic, retain) IdentityManager* identityManager;
@property (nonatomic, retain) TransportManager* transportManager;

- (id) initWithService: (MessageEncodeService*) service;

@end

@interface MessageEncodedNotifyOperation : NSOperation {
}

@end


@interface MessageEncodeOperation : NSOperation {
    // ManagedObject is not thread-safe, ObjectID is
    NSManagedObjectID* objId;
    MessageEncodeThread* thread;
    BOOL success;
}

@property (nonatomic, retain) NSManagedObjectID* objId;
@property (nonatomic, retain) MessageEncodeThread* thread;
@property (nonatomic, assign) BOOL success;

- (id) initWithObjId: (NSManagedObjectID*) oId onThread: (MessageEncodeThread*) thread;

@end