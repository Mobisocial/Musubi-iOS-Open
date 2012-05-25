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
//  Created by Willem Bult on 4/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedDataSource.h"
#import "ObjManager.h"
#import "Musubi.h"
#import "StatusObj.h"
#import "StatusObjItem.h"
#import "StatusObjItemCell.h"
#import "PictureObjItem.h"
#import "PictureObjItemCell.h"
#import "ObjFactory.h"
#import "MObj.h"
#import "MIdentity.h"
#import "FeedViewController.h"

#define kFeedDataSourceLoadMargin 20

@implementation FeedDataSource

- (id)initWithFeed:(MFeed *)feed {
    self = [super init];
    
    if (self) {
        dataModel = [[FeedDataModel alloc] initWithFeed:feed];        
        _loadingStarted = NO;
    }
    
    return self;
}

- (id<TTModel>)model {
    return dataModel;
}


- (void)tableViewDidLoadModel:(UITableView *)tableView {
    NSLog(@"Loaded model");
    
    if (!_loadingStarted) {
        _loadingStarted = YES;
        [self loadMoreForTableView:tableView];
    }
    
    [self setItems: [NSMutableArray arrayWithArray:[dataModel modelItems]]];
    _lastLoadedRow = self.items.count;
}

         
- (void) loadMoreForTableView: (UITableView*) tableView {

    [dataModel load:TTURLRequestCachePolicyDefault more: dataModel.modelItems.count > 0];    
    [((TTTableViewVarHeightDelegate*)tableView.delegate).controller performSelectorOnMainThread:@selector(refresh) withObject:nil waitUntilDone:YES]; 
    
    if (dataModel.hasMore) {
        // wait a little bit so we don't block the UI
        [self performSelector:@selector(loadMoreForTableView:) withObject:tableView afterDelay:.05];
    }
}

- (Class)tableView:(UITableView *)tableView cellClassForObject:(id)object {
    
    Class cls = nil;

    if ([object isKindOfClass:[StatusObjItem class]]) {  
        cls = [StatusObjItemCell class];  
    } else if ([object isKindOfClass:[PictureObjItem class]]) {
        cls = [PictureObjItemCell class];
    } else {
        cls = [super tableView:tableView cellClassForObject:object];
    }
    
    return cls;
}

@end
