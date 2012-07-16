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
//  IndexedTTTableView.m
//  musubi
//
//  Created by Ian Vo on 7/13/12.
//  Copyright (c) 2012 Stanford University. All rights reserved.
//

#import "IndexedTTTableView.h"

@implementation IndexedTTTableView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _indexPathRow = 0;
    }
    return self;
}

- (void) setIndexPathRow:(int)indexPathRow {
    _indexPathRow = indexPathRow;
}

- (int) getIndexPathRow {
    return _indexPathRow;
}

- (void) displayIndexPathRow {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_indexPathRow inSection:0];
    [self scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    [self reloadData];
}

@end
