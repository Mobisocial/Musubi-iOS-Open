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
#import <CoreData/CoreData.h>
#import "IdentityProvider.h"

@class MessageEncoder;
@class PersistentModelStoreFactory, PersistentModelStore, MusubiDeviceManager, IdentityManager, TransportManager;

@interface MessageEncodeService : NSObject {
    PersistentModelStoreFactory* _storeFactory;
    id<IdentityProvider> _identityProvider;
    
    NSArray* _queues;
    
    NSMutableArray* _pending;
}

@property (nonatomic) PersistentModelStoreFactory* storeFactory;
@property (nonatomic) id<IdentityProvider> identityProvider;

// List of operation threads
@property (nonatomic) NSArray* queues;

// List of objs that are pending processing
@property (atomic) NSMutableArray* pending;

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) sf andIdentityProvider: (id<IdentityProvider>) ip;

@end


@interface MessageEncodeOperation : NSOperation {
    // ManagedObject is not thread-safe, ObjectID is
    NSManagedObjectID* _objId;
    MessageEncodeService* _service;
    PersistentModelStore* _store;
    BOOL success;
}

@property (nonatomic) NSManagedObjectID* objId;
@property (nonatomic) MessageEncodeService* service;
@property (nonatomic) PersistentModelStore* store;
@property (nonatomic, assign) BOOL success;

- (id) initWithObjId: (NSManagedObjectID*) oId andService: (MessageEncodeService*) service;
@end

@interface MessageEncodedNotifyOperation : NSOperation
@end