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
#import "ManagedObjFeedItem.h"

@implementation PictureObjItemCell

+ (void)prepareItem:(ManagedObjFeedItem *)item {
    item.computedData = [UIImage imageWithData: item.managedObj.raw];
}

+ (CGFloat)renderHeightForItem:(ManagedObjFeedItem *)item {
    UIImage* image = item.computedData;
    return (250 / image.size.width) * image.size.height;
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

- (void)setObject:(ManagedObjFeedItem*)object {
    if (_item != object) {
        [super setObject:object];
        UIImage* image = object.computedData;
        [self.pictureView setImage: image];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.pictureView.frame = CGRectMake(self.detailTextLabel.frame.origin.x, self.detailTextLabel.frame.origin.y + 5, self.detailTextLabel.frame.size.width, self.detailTextLabel.frame.size.height);
}

@end
