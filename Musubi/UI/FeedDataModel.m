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
//  FeedDataModel.m
//  musubi
//
//  Created by Willem Bult on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedDataModel.h"
#import "ObjManager.h"
#import "ObjFactory.h"
#import "Musubi.h"
#import "MObj.h"
#import "MIdentity.h"
#import "StatusObj.h"
#import "StatusObjItem.h"
#import "PictureObj.h"
#import "PictureObjItem.h"

#define kFeedDataModelLoadInitialBatchSize 30
#define kFeedDataModelLoadBatchSize 5

@implementation FeedDataModel

@synthesize feed = _feed;
@synthesize mObjs = _mObjs, items = _items;
@synthesize hasMore = _hasMore;
@synthesize isOutdated = _outdated;

- (FeedDataModel *)initWithFeed:(MFeed *)feed {
    self = [super init];
    
    if (self) {
                
        [self setFeed: feed];
        _lastLoaded = 0;
        _hasMore = YES;
    }
    
    return self;
}

- (NSArray *)modelItems {
    return _items;
}

#pragma mark --
#pragma mark TTModel methods

- (void)load:(TTURLRequestCachePolicy)cachePolicy more:(BOOL)more {

    assert([[NSThread currentThread] isMainThread]);
    
    if (!more) {
        _done = NO;
        _loading = YES;
        
        _lastLoaded = 0;
        [self setItems:nil];
        
        ObjManager* objManager = [[ObjManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
        [self setMObjs:[objManager renderableObjsInFeed:_feed]];
    } else {
        _loadingMore = YES;
    }
    
    NSMutableArray *updatedItems = [NSMutableArray arrayWithArray:_items];
    int target = MIN(_mObjs.count, _lastLoaded + (_lastLoaded ? kFeedDataModelLoadBatchSize : kFeedDataModelLoadInitialBatchSize));
            
    for (int i=_lastLoaded; i < target; i++) {
        MObj* mObj = [_mObjs objectAtIndex:i];
        Obj* obj = [ObjFactory objFromManagedObj:mObj];
        
        id item = nil;
        if ([obj isMemberOfClass:[StatusObj class]]) {
            item = [[StatusObjItem alloc] init];
            [item setText: ((StatusObj*) obj).text];
        } else if ([obj isMemberOfClass:[PictureObj class]]) {
            item = [[PictureObjItem alloc] init];
            [item setPicture: ((PictureObj*) obj).image];
        }
        
        if (item) {
            [item setSender: [mObj senderDisplay]];
            [item setTimestamp: mObj.timestamp];
            [item setProfilePicture: [UIImage imageWithData:mObj.identity.thumbnail]];

            [updatedItems addObject:item];
        }
    }
    
    [self setItems:updatedItems];
    
    _lastLoaded = target;
    _hasMore = _lastLoaded < (_mObjs.count - 1);

    _done = YES;
    _loading = NO;
    _loadingMore = NO;
    _outdated = NO;
}

- (BOOL)isLoaded {
    return _done;
}

- (BOOL)isLoading {
    return _loading;
}

- (BOOL)isLoadingMore {
    return _loadingMore;
}
@end
