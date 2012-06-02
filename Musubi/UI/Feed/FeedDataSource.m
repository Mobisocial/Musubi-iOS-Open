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

#import "AppManager.h"
#import "IdentityManager.h"
#import "ObjManager.h"
#import "MIdentity.h"
#import "MObj.h"
#import "MLike.h"

#import "ObjHelper.h"
#import "ObjFactory.h"
#import "Obj.h"

#import "DeleteObj.h"

#import "StatusObj.h"
#import "StatusObjItemCell.h"

#import "PictureObj.h"
#import "PictureObjItemCell.h"

#import "UnknownObj.h"
#import "HtmlObjItemCell.h"

#import "IntroductionObj.h"
#import "IntroductionObjItemCell.h"

#import "VoiceObj.h"
#import "VoiceObjItemCell.h"

#import "VideoObj.h"
#import "VideoObjItemCell.h"

#import "FileObj.h"
#import "FileObjItemCell.h"

#import "StoryObj.h"
#import "StoryObjItemCell.h"

#import "ManagedObjFeedItem.h"

#import "Musubi.h"

@implementation FeedDataSource

- (id)initWithFeed:(MFeed *)feed  messagesNewerThan:(NSDate*)newerThan startingAt:(NSDate*)startingAt{
    self = [super init];
    
    if (!self)
        return nil;
    
    FeedModel* model = [[FeedModel alloc] initWithFeed:feed messagesNewerThan:newerThan];
    self.model = model;
    [model.delegates addObject:self];
    _objManager = [[ObjManager alloc] initWithStore:[Musubi sharedInstance].mainStore];

    return self;
}

- (FeedItem*) itemFromObj: (MObj*) mObj {
    MObj* managed = mObj;
    ManagedObjFeedItem* item = [[ManagedObjFeedItem alloc] initWithManagedObj:managed];

    NSString* renderMode = [item.parsedJson objectForKey:kObjFieldRenderMode];
    if ([kObjFieldRenderModeLatest isEqualToString:renderMode]) {
        MObj* child = [_objManager latestChildForParent:managed];
        if (child) {
            managed = child;
            item = [[ManagedObjFeedItem alloc] initWithManagedObj:managed];
        }
    }

    // todo: can avoid o(n) calls with:
    // item = [[ObjFactory implementationForObjType theType] cellClass]

    Class cellClass;
    if ([managed.type isEqualToString:kObjTypeStatus]) {
        cellClass = [StatusObjItemCell class];
    } else if ([managed.type isEqualToString:kObjTypePicture]) {
        cellClass = [PictureObjItemCell class];
    } else if ([managed.type isEqualToString: kObjTypeIntroduction]) {
        cellClass = [IntroductionObjItemCell class];
    } else if ([managed.type isEqualToString:kObjTypeVoice]) {
        cellClass = [VoiceObjItemCell class];
    } else if ([managed.type isEqualToString:kObjTypeStory]) {
        cellClass = [StoryObjItemCell class];
    } else if ([managed.type isEqualToString:kObjTypeVideo]) {
        cellClass = [VideoObjItemCell class];
    } else if ([managed.type isEqualToString:kObjTypeFile]) {
        cellClass = [FileObjItemCell class];
    }
    
    if (cellClass == nil) {
        Obj* obj = [ObjFactory objFromManagedObj:managed];
        if (nil != [obj.data objectForKey:kObjFieldHtml]) {
            cellClass = [HtmlObjItemCell class];
        } else if (nil != [obj.data objectForKey:kObjFieldText]) {
            cellClass = [StatusObjItemCell class];
        }   
    }

    if (cellClass) {
        item.cellClass = cellClass;
        [cellClass prepareItem: item];

        NSMutableDictionary* likes = [NSMutableDictionary dictionary];
        for (MLike* like in [_objManager likesForObj:managed]) {
            if (like.sender) {
                if (like.sender.owned) {
                    [item setILiked:YES];
                } else {
                    [likes setObject:[NSNumber numberWithInt:like.count] forKey:[IdentityManager displayNameForIdentity:like.sender]];
                }
            }
        }
        
        [item setObj: managed];
        [item setSender: [IdentityManager displayNameForIdentity:managed.identity]];
        [item setTimestamp: managed.timestamp];
        if(managed.identity.musubiThumbnail)
            [item setProfilePicture: [UIImage imageWithData:managed.identity.musubiThumbnail]];
        else
            [item setProfilePicture: [UIImage imageWithData:managed.identity.thumbnail]];
        [item setLikes: likes];
    }
    
    return item;
}

- (void)tableViewDidLoadModel:(UITableView *)tableView {
    // remove the "Load earlier" item first, so we can safely assume all items are FeedItems
    TTTableMoreButton* loadMoreButton = nil;
    if (self.items.count && [[self.items objectAtIndex:0] isKindOfClass:[TTTableMoreButton class]]) {
        [self.items removeObjectAtIndex:0];
    }
    
    loadMoreButton = [TTTableMoreButton itemWithText:@"Earlier messages..."];
    
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

- (MObj*)objForIndex:(int)i {
    FeedItem* feedItem = [self.items objectAtIndex:i];
    return feedItem.obj;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        PersistentModelStore* store = [Musubi sharedInstance].mainStore;

        AppManager* am = [[AppManager alloc] initWithStore:store];
        MApp* app = [am ensureSuperApp];

        FeedItem* feedItem = [self.items objectAtIndex:indexPath.row];

        id deleteObj = [[DeleteObj alloc] initWithTargetObj: feedItem.obj];
        FeedModel* feedModel = self.model;
        [ObjHelper sendObj:deleteObj toFeed:feedModel.feed fromApp:app usingStore:store];

        [tableView beginUpdates];
        [self.items removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates]; 
    } 
}

- (Class)tableView:(UITableView *)tableView cellClassForObject:(id)object {
    
    Class cls = nil;
    if ([object isKindOfClass:ManagedObjFeedItem.class]) {
        cls = [((ManagedObjFeedItem*)object) cellClass];
    }

    if (cls == nil) {
        cls = [super tableView:tableView cellClassForObject:object];
    }
    
    return cls;
}

@end

