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

@interface MessageEncodeService : NSObject
@property (nonatomic, strong) PersistentModelStoreFactory* storeFactory;
@property (nonatomic, strong) id<IdentityProvider> identityProvider;

// List of operation threads
@property (nonatomic, strong) NSArray* queues;

// List of objs that are pending processing
@property (nonatomic,strong) NSMutableArray* pending;
@property (nonatomic,strong) NSLock* pendingLock;

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) sf andIdentityProvider: (id<IdentityProvider>) ip;

@end


@interface MessageEncodeOperation : NSOperation {
    BOOL success;
}

@property (nonatomic, strong) NSManagedObjectID* objId;
@property (nonatomic, weak) MessageEncodeService* service;
@property (nonatomic, strong) PersistentModelStore* store;
@property (nonatomic, assign) BOOL success;

- (id) initWithObjId: (NSManagedObjectID*) oId andService: (MessageEncodeService*) service;
@end

@interface MessageEncodedNotifyOperation : NSOperation
@end