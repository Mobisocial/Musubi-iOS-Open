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
//  ObjPipelineService.h
//  musubi
//
//  Created by Willem Bult on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PersistentModelStoreFactory, PersistentModelStore, MObj, ObjProcessorThread, IdentityManager;

@interface ObjPipelineService : NSObject {
    PersistentModelStoreFactory* storeFactory;
    
    NSMutableArray* pending;
    NSOperationQueue* operations;
    
    NSMutableArray* feedsToNotify;
}

@property (nonatomic, retain) PersistentModelStoreFactory* storeFactory;

// List of objs that are pending processing
@property (atomic, retain) NSMutableArray* pending;
@property (nonatomic, retain) NSOperationQueue* operations;
@property (atomic, retain) NSMutableArray* feedsToNotify;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)sf;

@end



@interface ObjProcessorOperation : NSOperation {
    NSManagedObjectID* _objId;
    ObjPipelineService* _service;
    
    PersistentModelStore* _store;
}

@property (nonatomic, retain) NSManagedObjectID* objId;
@property (nonatomic, retain) PersistentModelStore* store;

- (id) initWithObjId: (NSManagedObjectID*) objId andService: (ObjPipelineService*) service;
- (void) processObj: (MObj*) obj;

@end