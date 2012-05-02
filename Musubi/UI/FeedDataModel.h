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
//  FeedDataModel.h
//  musubi
//
//  Created by Willem Bult on 4/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Three20/Three20.h"
#import "MFeed.h"

@interface FeedDataModel : TTModel {
    BOOL _done;
    BOOL _loading;
    BOOL _loadingMore;
    
    int _lastLoaded;
    BOOL _hasMore;
    
    NSArray* _mObjs;
    NSArray* _items;
}

@property (nonatomic, retain) NSArray* mObjs;
@property (nonatomic, retain) NSArray* items;
@property (nonatomic, readonly) BOOL hasMore;

- (FeedDataModel*) initWithFeed: (MFeed*) feed;
- (NSArray *)modelItems;

@end
