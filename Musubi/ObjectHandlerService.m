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
//  NSManagedObjectHandlerService.m
//  musubi
//
//  Created by Willem Bult on 6/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ManagedObjectHandlerService.h"
#import "PersistentModelStore.h"

@implementation ManagedObjectHandlerService

@synthesize storeFactory = _storeFactory, pending = _pending, queues = _queues, pendingLock = _pendingLock;

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) sf andOperation: (id<ManagedObjectHandlerOperation>) operation andQueues: (int) numberOfQueues {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    self.storeFactory = sf;
    
    // List of objs pending encoding
    self.pending = [NSMutableArray arrayWithCapacity:10];
    self.pendingLock = [[NSLock alloc] init];
    
    // Initialize the processing queues
    self.queues = [NSArray array];
    for (int i=0; i<numberOfQueues; i++) {
        NSOperationQueue* q = [NSOperationQueue new];
        q.maxConcurrentOperationCount = 1;
        [self.queues addObject: q];
    }
    
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(process:) name:kMusubiNotificationPlainObjReady object:nil];
    //in case we bailed with a message in the pipes
    [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationPlainObjReady object:nil];
    
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
    NSDate* weekAgo = [NSDate dateWithTimeIntervalSinceNow:-604800.0];
    for (MObj* obj in [store query:[NSPredicate predicateWithFormat:@"(encoded == nil) AND (lastModified > %@)", weekAgo] onEntity:@"Obj"]) {
        
        // The encoder apparently deleted this message already, move on
        if ([store isDeletedObject:obj])
            continue;
        
        [objs addObject:obj.objectID];
    }
    
    [self processObjsWithIds:objs];
}

- (void) processObjsWithIds: (NSArray*) objObjectIDs {
    // This is called on some background thread (through notificationCenter), so we need a new store
    PersistentModelStore* store = [_storeFactory newStore];
    
    NSMutableSet* usedQueues = [NSMutableSet setWithCapacity:2];
    
    for (NSManagedObjectID* objID in objObjectIDs) {
        
        MObj* obj = (MObj*)[store.context existingObjectWithID:objID error:nil];
        if (!obj)
            continue;
        
        assert (obj.encoded == nil);
        
        @synchronized(_pendingLock) {
            if ([_pending containsObject: objID]) {
                continue;
            } else {
                [_pending addObject: objID];
            }
        }
        
        // Find the thread to run this on
        NSOperationQueue* queue = nil;
        if([obj.feed.name isEqualToString:kFeedNameGlobalWhitelist] && obj.feed.type == kFeedTypeAsymmetric) {
            queue = [_queues objectAtIndex:0];
        } else {
            NSArray* members = [store query:[NSPredicate predicateWithFormat:@"feed = %@", obj.feed] onEntity:@"FeedMember"];
            if (members.count > kSmallProcessorCutOff) {
                queue = [_queues objectAtIndex:0];
            } else {
                queue = [_queues objectAtIndex:1];
            }
        }
        
        [usedQueues addObject: queue];
        [queue addOperation: [[MessageEncodeOperation alloc] initWithObjId:objID andService:self]];
    }
    
    // At the end, notify everybody
    for (NSOperationQueue* queue in usedQueues) {
        [queue addOperation: [[MessageEncodedNotifyOperation alloc] init]]; 
    }
}
@end
