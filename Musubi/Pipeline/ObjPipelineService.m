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
#import "ObjManager.h"
#import "IdentityManager.h"
#import "Obj.h"
#import "ObjFactory.h"
#import "ObjHelper.h"
#import "NSData+HexString.h"

@implementation ObjPipelineService

@synthesize storeFactory, pending, operations, feedsToNotify, pendingParentHashes;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)sf {
    self = [super init];
    if (!self)
        return nil;
    
    self.storeFactory = sf;
    
    // List of objs pending processing
    self.pending =[NSMutableArray arrayWithCapacity:10];
    self.pendingParentHashes = [NSMutableDictionary dictionary];
    
    // Operation queue with a single thread
    self.operations = [NSOperationQueue new];
    [operations setMaxConcurrentOperationCount: 1];
    
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(process) name:kMusubiNotificationAppObjReady object:nil];
    [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationAppObjReady object:nil];
    
    return self;
}

- (void) process {
    // This is called on some background thread (through notificationCenter), so we need a new store
    PersistentModelStore* store = [storeFactory newStore];
    
    for (MObj* obj in [store query:[NSPredicate predicateWithFormat:@"(processed == NO) AND (encoded != nil)"] onEntity:@"Obj"]) {
        @try
        {
            if(obj.processed == YES) {
                NSLog(@"Shut 'er down clancy, she's a pumpin' mud!!");
                continue;
            }
        }
        @catch (NSException *exception)
        {
            if ([[exception name] isEqualToString:NSObjectInaccessibleException]) {
                //another thread deleted this row, so just move on
                continue;
            }
        }

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

static int operationCount = 0;

@synthesize objId = _objId, store = _store, service = _service;

- (id)initWithObjId:(NSManagedObjectID *)objId andService:(ObjPipelineService *)service {
    self = [super init];
    if (self) {
        self.service = service;
        self.objId = objId;
        [self setThreadPriority: kMusubiThreadPriorityBackground];
    }
    return self;
}

- (void)main {
    _store = [_service.storeFactory newStore];
    
    operationCount++;

    // Get the obj and decode it
    MObj* obj = (MObj*)[_store queryFirst:[NSPredicate predicateWithFormat:@"self == %@", _objId] onEntity:@"Obj"];
    
    if (obj) {
        @try {
            [self processObj: obj];
        } @catch (NSException *e) {
            NSLog(@"Error while processing obj: %@", e);
            [_store.context deleteObject: obj];
        } @finally {
            operationCount--;
        }
    }
    
    // Remove from the pending queue
    [_service.pending removeObject:_objId];
}

+ (int) operationCount {
    return operationCount;
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

    NSError* error;
    NSDictionary*parsedJson = [NSJSONSerialization JSONObjectWithData:[mObj.json dataUsingEncoding:NSUnicodeStringEncoding] options:0 error:&error];
    NSString* targetHash = [parsedJson objectForKey:kObjFieldTargetHash];
    if (targetHash != nil) {
        NSString* targetRelation = [parsedJson objectForKey:kObjFieldTargetRelation];
        if (targetRelation == nil || [targetRelation isEqualToString:kObjFieldRelationParent]) {
            NSData* hash = [targetHash dataFromHex];
            ObjManager* objMgr = [[ObjManager alloc] initWithStore: _store];
            MObj* parentObj = [objMgr objWithUniversalHash: hash];
            if (parentObj == nil) {
                NSLog(@"Waiting for parent %@", targetHash);
                @synchronized(self.service.pendingParentHashes) {
                    NSMutableArray* children = [self.service.pendingParentHashes objectForKey:targetHash];
                    if(children == nil) {
                        children = [NSMutableArray array];
                        [self.service.pendingParentHashes setObject:children forKey:targetHash];
                    }
                    [children addObject:mObj.objectID];
                    mObj.processed = YES;
                    [_store save];
                }
                return;
            }
            mObj.parent = parentObj;
        }
    }

    Obj* obj = [ObjFactory objFromManagedObj:mObj];
    if ([ObjHelper isRenderable: obj]) {
        [mObj setRenderable: YES];
        [feed setLatestRenderableObjTime: [mObj.timestamp timeIntervalSince1970]];
        [feed setLatestRenderableObj: mObj];
        
        if (!sender.owned) {
            [feed setNumUnread: feed.numUnread + 1];
        }
        [_service.feedsToNotify addObject:feed.objectID];
    }

    BOOL keepObject = [obj processObjWithRecord: mObj];
    if (keepObject) {
        mObj.processed = YES;
    } else {
        NSLog(@"Discarding %@", mObj.type);
        [_store.context deleteObject: mObj];
    }
    
    FeedManager* feedManager = [[FeedManager alloc] initWithStore: _store];
    if (feed.type == kFeedTypeOneTimeUse) {
        [feedManager deleteFeedAndMembers: feed];
    }
    
    [_store save];
    
    NSLog(@"Processed: %@", obj);
    
    [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationUpdatedFeed object:feed.objectID];

    NSMutableArray* children = nil;
    @synchronized(self.service.pendingParentHashes) {
        children = [self.service.pendingParentHashes objectForKey:targetHash];
        [self.service.pendingParentHashes removeObjectForKey:targetHash];
    }
    
    if(children != nil && children.count) {
        for(NSManagedObjectID* oid in children) {
            NSError* error;
            MObj* child = [_store.context existingObjectWithID:oid error:&error];
            if(!child)
                continue;
            [child.processed = NO];
        }
        [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationAppObjReady object:nil];
        [_store save];
    }
}

@end