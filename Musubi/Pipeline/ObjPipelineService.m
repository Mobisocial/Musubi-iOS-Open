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
//  ObjPipelineService.m
//  musubi
//
//  Created by Willem Bult on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ObjPipelineService.h"
#import "PersistentModelStore.h"
#import "Musubi.h"
#import "MObj.h"
#import "MIdentity.h"
#import "MFeed.h"
#import "FeedManager.h"
#import "IdentityManager.h"
#import "Obj.h"
#import "ObjFactory.h"
#import "ObjHelper.h"

@implementation ObjPipelineService

@synthesize storeFactory, pending, operations, feedsToNotify;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)sf {
    self = [super init];
    if (self) {
        [self setStoreFactory:sf];
        
        // List of objs pending processing
        [self setPending: [NSMutableArray arrayWithCapacity:10]];
        
        // Operation queue with a single thread
        [self setOperations: [NSOperationQueue new]];
        [operations setMaxConcurrentOperationCount: 1];
        
        [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(process) name:kMusubiNotificationAppObjReady object:nil];
        [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationAppObjReady object:nil];
    }
    
    return self;
}

- (void) process {
    // This is called on some background thread (through notificationCenter), so we need a new store
    PersistentModelStore* store = [storeFactory newStore];
    
    for (MObj* obj in [store query:[NSPredicate predicateWithFormat:@"(processed == NO) AND (encoded != nil)"] onEntity:@"Obj"]) {
        assert(obj.processed == NO);
        
        if (obj.processed)
            continue;
        
        // Don't process the same obj twice in different threads
        // pending is atomic, so we should be able to do this safely
        // Store ObjectID instead of object, because that is thread-safe
        if ([pending containsObject: obj.objectID]) {
            continue;
        } else {
            [pending addObject: obj.objectID];
        }
        
        [operations addOperation: [[ObjProcessorOperation alloc] initWithObjId:obj.objectID andService:self]];
    }
}

@end

@implementation ObjProcessorOperation

@synthesize objId = _objId, store = _store, service = _service;

- (id)initWithObjId:(NSManagedObjectID *)objId andService:(ObjPipelineService *)service {
    self = [super init];
    if (self) {
        self.service = service;
        self.objId = objId;
    }
    return self;
}

- (void)main {
    _store = [_service.storeFactory newStore];
    
    // Get the obj and decode it
    MObj* obj = (MObj*)[_store queryFirst:[NSPredicate predicateWithFormat:@"self == %@", _objId] onEntity:@"Obj"];
    
    if (obj) {
        [self processObj: obj];
    }
    
    // Remove from the pending queue
    [_service.pending removeObject:_objId];
}

- (void) processObj:(MObj*)mObj {
    
    MIdentity* sender = mObj.identity;
    MFeed* feed = mObj.feed;    
    assert (mObj != nil);
    assert (mObj.universalHash != nil);
    assert (!mObj.processed);
    assert (mObj.shortUniversalHash == *(uint64_t *)mObj.universalHash.bytes);
    
    if (mObj.processed)
        return;
    
    Obj* obj = [ObjFactory objFromManagedObj:mObj];
    
    if ([ObjHelper isRenderable: obj]) {
        [mObj setRenderable: YES];
        [feed setLatestRenderableObjTime: [[NSDate date] timeIntervalSince1970]];
        [feed setLatestRenderableObj: mObj];
        
        if (!sender.owned) {
            [feed setNumUnread: feed.numUnread + 1];
        }
        [_service.feedsToNotify addObject:feed.objectID];
    }
    
    [mObj setProcessed: YES];
    
    FeedManager* feedManager = [[FeedManager alloc] initWithStore: _store];
    if (feed.type == kFeedTypeOneTimeUse) {
        [feedManager deleteFeedAndMembers: feed];
    }
    
    [_store save];
    
    NSLog(@"Processed: %@", obj);
    
    [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationUpdatedFeed object:feed.objectID];
}

@end