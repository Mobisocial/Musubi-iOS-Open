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
//  Created by Willem Bult on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedListDataSource.h"
#import "MFeed.h"
#import "FeedManager.h"
#import "FeedListModel.h"
#import "FeedListItem.h"
#import "FeedListItemCell.h"
#import "Musubi.h"

@implementation FeedListDataSource

- (id) init {
    self = [super init];
    if (self) {
        self.model = [[FeedListModel alloc] init];
        _feedManager = [[FeedManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    }
    return self;
}


- (void)tableViewDidLoadModel:(UITableView *)tableView {
    NSMutableArray* newItems = [NSMutableArray array];

    for (MFeed* mFeed in ((FeedListModel*)self.model).results) {
        FeedListItem* item = [[FeedListItem alloc] initWithFeed:mFeed];
        if (item) {
            [newItems addObject: item];
        }
    }
    
    self.items = newItems;
}

- (Class)tableView:(UITableView *)tableView cellClassForObject:(id)object {
    return [FeedListItemCell class];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) { 
        FeedListItem* item = [self.items objectAtIndex:indexPath.row];
        [_feedManager deleteFeedAndMembersAndObjs:item.feed];

        [tableView beginUpdates];
        [self.items removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObjects:indexPath,nil] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
    } 
}


@end
