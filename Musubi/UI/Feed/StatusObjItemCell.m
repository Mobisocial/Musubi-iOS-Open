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
//  StatusObjItemCell.m
//  musubi
//
//  Created by Willem Bult on 4/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StatusObjItemCell.h"
#import "StatusObjItem.h"

@implementation StatusObjItemCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {        
        self.detailTextLabel.contentMode = UIViewContentModeTop | UIViewContentModeLeft;
        self.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
        self.detailTextLabel.numberOfLines = 0;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.detailTextLabel.contentMode = UIViewContentModeTop | UIViewContentModeLeft;
    self.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    self.detailTextLabel.numberOfLines = 0;
    self.detailTextLabel.frame = CGRectMake(self.detailTextLabel.frame.origin.x, self.detailTextLabel.frame.origin.y, 300, self.frame.size.height - self.detailTextLabel.frame.origin.y - 10);
}


+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)object {
    
    StatusObjItem* item = object;
    CGSize size = [item.text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(300, 1024) lineBreakMode:UILineBreakModeWordWrap];
    return size.height + 40;
}

@end
