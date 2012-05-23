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
//  PictureObjItemCell.m
//  musubi
//
//  Created by Willem Bult on 5/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PictureObjItemCell.h"
#import "PictureObjItem.h"

@implementation PictureObjItemCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    
    return self;
}

- (void)setObject:(id)object {
    if (_item != object) {
        [super setObject:object];
        
        PictureObjItem* item = object;
        [self.pictureView setImage: item.picture];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
//    self.pictureView.frame = CGRectMake(10, 25, 300, self.frame.size.height - 25);
    self.pictureView.frame = CGRectMake(self.detailTextLabel.frame.origin.x, self.detailTextLabel.frame.origin.y + 5, self.detailTextLabel.frame.size.width, self.detailTextLabel.frame.size.height);
}

- (UIImageView *)pictureView {
    if (!_pictureView) {
        _pictureView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        [_pictureView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [_pictureView setContentMode:UIViewContentModeScaleAspectFit];
        [self.contentView addSubview:_pictureView];
    }
    
    return _pictureView;
}

/*

+ (CGFloat)tableView:(UITableView*)tableView rowHeightForObject:(id)object {
    
    PictureObjItem* item = object;
    return (267 /item.picture.size.width) * item.picture.size.height + 40;
}*/

+ (CGFloat)renderHeightForItem:(FeedItem *)item {
    return (267 /((PictureObjItem*)item).picture.size.width) * ((PictureObjItem*)item).picture.size.height + 40;    
}

@end
