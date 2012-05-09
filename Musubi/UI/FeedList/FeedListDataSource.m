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
//  FeedListDataSource.m
//  musubi
//
//  Created by Willem Bult on 5/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedListDataSource.h"
#import "FeedManager.h"
#import "Musubi.h"
#import "MFeed.h"
#import "FeedListItemCell.h"
#import "MObj.h"

@implementation FeedListDataSource

@synthesize feedManager;

- (id)init {
    self = [super init];
    if (self) {
        [self setFeedManager:[[FeedManager alloc] initWithStore: [Musubi sharedInstance].mainStore]];
        [self load:TTURLRequestCachePolicyDefault more:NO];
    }
    return self;
}


- (void)load:(TTURLRequestCachePolicy)cachePolicy more:(BOOL)more {
    NSMutableArray* updatedFeeds = [NSMutableArray arrayWithArray:[feedManager displayFeeds]];
    [self setItems: updatedFeeds];
}

- (BOOL)isLoaded {
    return YES;
}

- (MFeed*)feedForIndex:(int)i {
    return [self.items objectAtIndex:i];
}

- (id)tableView:(UITableView *)tableView objectForRowAtIndexPath:(NSIndexPath *)indexPath {
    MFeed* feed = [self feedForIndex:indexPath.row];
    
    NSString* unread = @"";
    
    if (feed.numUnread > 0) {
        unread = [NSString stringWithFormat:@"%d unread", feed.numUnread];
    }
    
    TTTableMessageItem* item = [TTTableMessageItem itemWithTitle:[feedManager identityStringForFeed:feed] caption:unread text:nil timestamp:[NSDate dateWithTimeIntervalSince1970:feed.latestRenderableObjTime] URL:nil];

    return item;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) { 
        MFeed* feed = [self feedForIndex:indexPath.row];
        [feedManager deleteFeedAndMembersAndObjs:feed];
        
        [tableView beginUpdates];
        [_items removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates]; 
    } 
}

- (Class)tableView:(UITableView *)tableView cellClassForObject:(id)object {
    return [FeedListItemCell class];
}

@end
