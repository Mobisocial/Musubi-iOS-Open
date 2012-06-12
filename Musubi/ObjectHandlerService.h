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
//  NSManagedObjectHandlerService.h
//  musubi
//
//  Created by Willem Bult on 6/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PersistentModelStoreFactory, ManagedObjectHandlerOperation;

@interface ManagedObjectHandlerServiceConfiguration : NSObject

@property (nonatomic, strong) NSString* notification;
@property (nonatomic, strong) ManagedObjectHandlerOperation* operation;
@property (nonatomic, assign) int numberOfQueues;


@end

@interface ManagedObjectHandlerService : NSObject

@property (nonatomic, retain) PersistentModelStoreFactory* storeFactory;
@property (nonatomic, strong) NSMutableArray* pending;
@property (nonatomic, strong) NSMutableArray* queues;
@property (nonatomic, strong) NSLock* pendingLock;

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) sf andConfiguration: (ManagedObjectHandlerServiceConfiguration*) config;

@end

@interface ManagedObjectHandlerOperation : NSOperation

- (id) initWithObjectId: (NSManagedObjectID*) objId andService: (ManagedObjectHandlerService*) service;

@property (nonatomic, retain) ManagedObjectHandlerService* service;

@end