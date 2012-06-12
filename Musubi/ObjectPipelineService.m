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
//  ObjectPipelineService.m
//  musubi
//
//  Created by Willem Bult on 6/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ObjectPipelineService.h"
#import "PersistentModelStore.h"
#import "Musubi.h"

@implementation ObjectPipelineServiceConfiguration

@synthesize model = _model, selector = _selector, notificationName = _notificationName, operationClass = _operationClass, numberOfQueues = _numberOfQueues, queueSelector = _queueSelector;

@end

@implementation ObjectPipelineService

@synthesize storeFactory = _storeFactory, pending = _pending, queues = _queues, pendingLock = _pendingLock, config = _config;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)sf andConfiguration:(ObjectPipelineServiceConfiguration *)config {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.storeFactory = sf;
    self.config = config;
    
    // List of objs pending encoding
    self.pending = [NSMutableArray arrayWithCapacity:10];
    self.pendingLock = [[NSLock alloc] init];
    
    // Initialize the processing queues
    self.queues = [NSMutableArray array];
    for (int i=0; i<config.numberOfQueues; i++) {
        NSOperationQueue* q = [NSOperationQueue new];
        q.maxConcurrentOperationCount = 1;
        [self.queues addObject: q];
    }
    
    // Listen on the specified notification
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(process:) name:config.notificationName object:nil];
    
    // Do an initial run
    [self process:nil];
    
    return self;
}

- (void) process: (NSNotification*) notification {
    NSManagedObjectID* specificId = nil;
    
    if (notification.object != nil && [notification.object isKindOfClass:[NSManagedObjectID class]]) {
        specificId = notification.object;
    }
    
    if (specificId) {
        [self processObjsWithIds:[NSArray arrayWithObject:specificId]];
    } else {
        [self processPendingObjs];
    }
}

- (void) processPendingObjs {
    
    // This may be called on some background thread (through notificationCenter), so we need a new store
    PersistentModelStore* store = [_storeFactory newStore];
    
    NSMutableArray* objs = [NSMutableArray array];
    for (NSManagedObject* obj in [store query:_config.selector onEntity:_config.model]) {
        
        // Don't deal with deleted objects
        if ([store isDeletedObject:obj])
            continue;
        
        [objs addObject:obj.objectID];
    }
    
    [self processObjsWithIds:objs];
}

- (void) processObjsWithIds: (NSArray*) objectIds {
    NSLog(@"Running with %@", objectIds);
    
    // This is called on some background thread (through notificationCenter), so we need a new store
    PersistentModelStore* store = [_storeFactory newStore];
    
    NSMutableSet* usedQueues = [NSMutableSet setWithCapacity:2];
    
    for (NSManagedObjectID* objectID in objectIds) {
        
        NSManagedObject* object = [store.context existingObjectWithID:objectID error:nil];
        if (!object) {
            NSLog(@"Object with id %@ not found", objectID);
            continue;
        }
            
        
        @synchronized(_pendingLock) {
            if ([_pending containsObject: objectID]) {
                continue;
            } else {
                [_pending addObject: objectID];
            }
        }
        
        int selectedQueue = 0;
        if (_config.queueSelector) {
            selectedQueue = _config.queueSelector(object);
        }
        
        
        NSOperationQueue* queue = [_queues objectAtIndex:selectedQueue];
        [usedQueues addObject: queue];
        NSOperation* operation = [((ObjectPipelineOperation*)[_config.operationClass alloc]) initWithObjectId:objectID andService:self];
        [queue addOperation: operation];
    }
}

@end


@implementation ObjectPipelineOperation

@synthesize objId = _objId, service = _service, store = _store;

- (id)initWithObjectId:(NSManagedObjectID *)objId andService:(ObjectPipelineService *)service {
    self = [super init];
    if (self) {
        _objId = objId;
        _service = service;
        self.threadPriority = kMusubiThreadPriorityBackground;
    }
    return self;
}

- (void) main {
    _store = [_service.storeFactory newStore];
    
    NSError* error;
    assert (!_objId.isTemporaryID);
    NSLog(@"Getting %@", _objId);
    NSManagedObject* obj = [_store.context existingObjectWithID:_objId error:&error];
    
    BOOL done = NO;
    
    if(obj == nil) {
        // Don't process any objects that don't exist
        done = YES;
    } else if ([self performOperationOnObject: obj]) {
        // Remove from the pending queue
        done = YES;
    }
    
    if (done) {
        @synchronized(_service.pendingLock) {
            [_service.pending removeObject:_objId];
        }
    }
}

- (BOOL)performOperationOnObject:(NSManagedObject *)object {
    return FALSE;
}

- (void) log:(NSString*) format, ... {
    va_list args;
    va_start(args, format);
    NSLogv([NSString stringWithFormat: @"%@: %@", self.class, format], args);
    va_end(args);
}

@end