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
//  ObjManager.m
//  Musubi
//
//  Created by Willem Bult on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ObjManager.h"
#import "SBJSON.h"
#import "MObj.h"
#import "MFeed.h"
#import "Obj.h"
#import "MLikeCache.h"
#import "MLike.h"
#import "MIdentity.h"
#import "PersistentModelStore.h"
#import "StatusObj.h"

@implementation ObjManager

- (id)initWithStore:(PersistentModelStore *)s {
    self = [super initWithEntityName:@"Obj" andStore:s];
    if (self) {
        
    }
    return self;
}

- (MObj*) create {
    return (MObj*) [super create];
}

- (MObj*) createFromObj: (Obj*) obj onFeed: (MFeed*) feed {
    
    SBJsonWriter* writer = [[SBJsonWriter alloc] init];
    NSString* json = [writer stringWithObject:obj.data];
    
    MObj* mObj = [self create];
    [mObj setType: obj.type];
    [mObj setJson: json];
    [mObj setRaw: obj.raw];
    [mObj setFeed: feed];
    
    return mObj;
}

- (MObj*) objWithUniversalHash: (NSData*) hashData {
    uint64_t shortHash = *(uint64_t*)hashData.bytes;
    return (MObj*)[self queryFirst:[NSPredicate predicateWithFormat:@"(shortUniversalHash == %lld)", shortHash]]; 
}

- (MObj*) latestChildForParent: (MObj *)parent {
    NSArray *res = [self query:[NSPredicate predicateWithFormat:@"(parent == %@)", parent] sortBy:[NSSortDescriptor sortDescriptorWithKey:@"intKey" ascending:false] limit:1];
    if (res.count == 0) {
        return nil;
    }
    return (MObj*)[res objectAtIndex:0];
}

- (MObj*)latestStatusObjInFeed:(MFeed *)feed {
    NSArray* res = [self query:[NSPredicate predicateWithFormat:@"(feed == %@) AND (parent == nil) AND (renderable == YES) AND ((processed == YES) OR (encoded == nil)) AND (type == %@)", feed.objectID, kObjTypeStatus] sortBy:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:FALSE] limit:1];
    if (res.count > 0) {
        return [res objectAtIndex:0];
    } else {
        return nil;
    }
}


- (NSArray *)renderableObjsInFeed:(MFeed *)feed {
    return [self renderableObjsInFeed:feed limit:-1];
}

- (NSArray *)renderableObjsInFeed:(MFeed *)feed limit:(NSInteger)limit {
    return [self query:[NSPredicate predicateWithFormat:@"(feed == %@) AND (parent == nil) AND (renderable == YES) AND ((processed == YES) OR (encoded == nil))", feed.objectID] sortBy:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:FALSE] limit:limit];
}

- (NSArray *)renderableObjsInFeed:(MFeed *)feed before:(NSDate*)beforeDate limit:(NSInteger)limit {
    return [self query:[NSPredicate predicateWithFormat:@"(feed == %@) AND (parent == nil) AND (renderable == YES) AND ((processed == YES) OR (encoded == nil)) AND (timestamp < %@)", feed.objectID, beforeDate] sortBy:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:FALSE] limit:limit];
}

- (NSArray *)renderableObjsInFeed:(MFeed *)feed after:(NSDate*)afterDate limit:(NSInteger)limit {
    return [self query:[NSPredicate predicateWithFormat:@"(feed == %@) AND (parent == nil) AND (renderable == YES) AND ((processed == YES) OR (encoded == nil)) AND (timestamp > %@)", feed.objectID, afterDate] sortBy:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:FALSE] limit:limit];
}

- (NSArray *) likesForObj: (MObj*) obj {
    return [store query:[NSPredicate predicateWithFormat:@"(obj == %@)", obj] onEntity:@"Like"];
}

- (void) saveLikeForObj: (MObj*) obj from: (MIdentity*) sender {
    
    // Need to get a sender in the current store context
    MIdentity* contextedSender = (MIdentity*)[store queryFirst:[NSPredicate predicateWithFormat:@"(self == %@)", sender.objectID] onEntity:@"Identity"];
    
    BOOL matched = NO;
    for (MLike* like in [store query:[NSPredicate predicateWithFormat:@"(obj == %@) AND (sender == %@)", obj, contextedSender] onEntity:@"Like"]) {
        if ([like.obj.objectID isEqual: obj.objectID]) {
            like.count += 1;
            matched = YES;
            break;
        }
    }
    
    if (!matched) {
        MLike* like = [NSEntityDescription insertNewObjectForEntityForName:@"Like" inManagedObjectContext: [store context]];

        like.obj = obj;
        like.sender = contextedSender;
        like.count = 1;
    }
    
    [store save];
}

- (MLikeCache*) likeCountForObj: (MObj*) obj {
    return (MLikeCache*)[store queryFirst:[NSPredicate predicateWithFormat:@"(parentObj == %@)", obj] onEntity:@"LikeCache"];
}

- (void) increaseLikeCountForObj: (MObj*) obj local: (BOOL) local {
    MLikeCache* likes = [self likeCountForObj:obj];
    
    if (!likes) {
        likes = [NSEntityDescription insertNewObjectForEntityForName:@"LikeCache" inManagedObjectContext: [store context]];
        likes.parentObj = obj;
    }
    
    likes.count += 1;
    
    if (local)
        likes.localLike += 1;
    
    [store save];
}

- (MObj*) deleteObjWithHash: (NSData *) hash {
    MObj* obj = [self objWithUniversalHash:hash];
    if (obj != nil) {
        [store.context deleteObject: obj];
        [store save];
    }
    return obj;
}

@end
