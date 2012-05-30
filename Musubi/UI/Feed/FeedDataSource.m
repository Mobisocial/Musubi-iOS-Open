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
//  FeedDataSource.m
//  musubi
//
//  Created by Willem Bult on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedDataSource.h"
#import "FeedModel.h"
#import "FeedItem.h"

#import "IdentityManager.h"
#import "ObjManager.h"
#import "MIdentity.h"
#import "MObj.h"
#import "MLike.h"

#import "ObjHelper.h"
#import "ObjFactory.h"
#import "Obj.h"

#import "StatusObj.h"
#import "StatusObjItemCell.h"

#import "PictureObj.h"
#import "PictureObjItem.h"
#import "PictureObjItemCell.h"

#import "UnknownObj.h"
#import "HtmlObjItem.h"
#import "HtmlObjItemCell.h"

#import "IntroductionObj.h"
#import "IntroductionObjItemCell.h"

#import "ManagedObjItem.h"

#import "Musubi.h"

@implementation FeedDataSource

- (id)initWithFeed:(MFeed *)feed {
    self = [super init];
    
    if (self) {
        self.model = [[FeedModel alloc] initWithFeed:feed];
        [((FeedModel*)self.model).delegates addObject:self];
        _objManager = [[ObjManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
                    
    }
    
    return self;
}

- (FeedItem*) itemFromObj: (MObj*) mObj {
    Obj* obj = [ObjFactory objFromManagedObj:mObj];
    FeedItem* item = nil;

    NSString* renderMode = [obj.data objectForKey:kObjFieldRenderMode];
    if ([kObjFieldRenderModeLatest isEqualToString:renderMode]) {
        MObj* child = [_objManager latestChildForParent:mObj];
        if (child) {
            NSLog(@"Got a child %@", child);
            obj = [ObjFactory objFromManagedObj:child];
        }
    }

    // todo: can avoid o(n) calls with:
    // item = [[[obj renderClass] alloc] initWithData obj]
    // item = [[[[ObjFactory implForManagedObj:mObj] alloc] initWithManagedObj obj]]

    if ([obj isMemberOfClass:[StatusObj class]]) {
        item = [[ManagedObjItem alloc] initWithManagedObj:mObj cellClass:[StatusObjItemCell class]];
    } else if ([obj isMemberOfClass:[PictureObj class]]) {
        item = [[PictureObjItem alloc] init];
        [(PictureObjItem*)item setPicture: ((PictureObj*) obj).image];
    } else if ([obj isMemberOfClass:[IntroductionObj class]]) {
        item = [[ManagedObjItem alloc] initWithManagedObj:mObj cellClass:[IntroductionObjItemCell class]];
    } else if (nil != [obj.data objectForKey:kObjFieldHtml]) {
        NSString* html = [obj.data objectForKey:kObjFieldHtml];
        item = [[HtmlObjItem alloc] initWithHtml:html];
    } else if (nil != [obj.data objectForKey:kObjFieldText]) {
        item = [[ManagedObjItem alloc] initWithManagedObj:mObj cellClass:[StatusObjItemCell class]];
    }

    if (item) {
        NSMutableDictionary* likes = [NSMutableDictionary dictionary];
        
        for (MLike* like in [_objManager likesForObj:mObj]) {
            if (like.sender) {
                if (like.sender.owned) {
                    [item setILiked:YES];
                } else {
                    [likes setObject:[NSNumber numberWithInt:like.count] forKey:[IdentityManager displayNameForIdentity:like.sender]];
                }
            }
        }
        
        [item setObj: mObj];
        [item setSender: [IdentityManager displayNameForIdentity:mObj.identity]];
        [item setTimestamp: mObj.timestamp];
        if(mObj.identity.musubiThumbnail)
            [item setProfilePicture: [UIImage imageWithData:mObj.identity.musubiThumbnail]];
        else
            [item setProfilePicture: [UIImage imageWithData:mObj.identity.thumbnail]];
        [item setLikes: likes];
    }
    
    return item;
}

- (void)tableViewDidLoadModel:(UITableView *)tableView {
    // remove the "Load earlier" item first, so we can safely assume all items are FeedItems
    TTTableMoreButton* loadMoreButton = nil;
    if (self.items.count && [[self.items objectAtIndex:0] isKindOfClass:[TTTableMoreButton class]]) {
//        loadMoreButton = [self.items objectAtIndex:0];
        [self.items removeObjectAtIndex:0];
    }
    //else {
        loadMoreButton = [TTTableMoreButton itemWithText:@"Earlier messages..."];
//    }
    
    for (MObj *mObj in [(FeedModel*)self.model consumeNewResults]) {
        FeedItem* item = [self itemFromObj:mObj];

        if (item) {
            // find correct position to insert feed item based on timestamp
            if (self.items.count == 0 || [item.timestamp compare:((FeedItem*)[self.items lastObject]).timestamp] > 0) {
                [self.items addObject: item];
            } else if ([item.timestamp compare:((FeedItem*)[self.items objectAtIndex:0]).timestamp] < 0) {
                [self.items insertObject:item atIndex:0];
            } else {
                for (int i = 0; i < self.items.count; i++) {
                    FeedItem* existing = [self.items objectAtIndex:i];
                    
                    // Replace item for identical obj (updated obj)
                    if ([existing.obj.objectID isEqual:item.obj.objectID]) {
                        [self.items replaceObjectAtIndex:i withObject:item];
                        break;
                    }
                    
                    // Insert here (will always be found because we tested timestamp out of bounds already)
                    if ([item.timestamp compare: existing.timestamp] < 0) {
                        [self.items insertObject:item atIndex:i];
                        break;
                    }
                }
            }
        }
    }
    
    // Now add the "load more" button back
    if (((FeedModel*)self.model).hasMore) {
        loadMoreButton.isLoading = NO;
        [self.items insertObject:loadMoreButton atIndex:0];
    }
}

- (Class)tableView:(UITableView *)tableView cellClassForObject:(id)object {
    
    Class cls = nil;

    // TODO: get rid of this switch statement, use the cellClass
    // from ManagedObjItem in its place.
    // This class's setObject: does the heavy work of preparing the UI given the data.
    if ([object isKindOfClass:ManagedObjItem.class]) {
        cls = [((ManagedObjItem*)object) cellClass];
    } else if ([object isKindOfClass:PictureObjItem.class]) {
        cls = [PictureObjItemCell class];
    } else if ([object isKindOfClass:HtmlObjItem.class]) {
        cls = [HtmlObjItemCell class];
    }

    if (cls == nil) {
        cls = [super tableView:tableView cellClassForObject:object];
    }
    
    return cls;
}

@end

