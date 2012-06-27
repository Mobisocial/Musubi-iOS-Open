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
#import "ObjHelper.h"
#import "UIViewAdditions.h"

@implementation PictureObjItemCell

+ (void)prepareItem:(ManagedObjFeedItem *)item {
    item.computedData = [UIImage imageWithData: item.managedObj.raw];
}

+ (NSString*) textForItem: (ManagedObjFeedItem*) item {
    NSString* text = nil;
    text = [[item parsedJson] objectForKey: kObjFieldText];
    if (text == nil) {
        text = [[item parsedJson] objectForKey: kObjFieldStatusText];
    }
    return text;
}

+ (CGFloat) pictureHeightForImage:(UIImage*)image {
    if (image.size.width > 250) {
        return (250 / image.size.width) * image.size.height;
    } else {
        return image.size.height;
    }
}

+ (CGFloat) pictureHeightForItem:(ManagedObjFeedItem*) item {
    UIImage* image = item.computedData;
    if(!image)
        image = [UIImage imageNamed:@"error.png"];

    return [PictureObjItemCell pictureHeightForImage:image];
}

+ (CGFloat) textHeightForItem: (ManagedObjFeedItem*) item {
    CGSize size = [[PictureObjItemCell textForItem: (ManagedObjFeedItem*)item] sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(244, 1024) lineBreakMode:UILineBreakModeWordWrap];
    
    return size.height;
}

+ (CGFloat)renderHeightForItem:(ManagedObjFeedItem *)item {
    return [PictureObjItemCell pictureHeightForItem:item] + [PictureObjItemCell textHeightForItem:item] + kTableCellSmallMargin;
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
        if (object.computedData != nil) {
            self.pictureView.image = object.computedData;
        } else {
            self.pictureView.image = [UIImage imageNamed:@"error.png"];
        }
        
        NSString* text = [PictureObjItemCell textForItem:(ManagedObjFeedItem*)object];
        self.detailTextLabel.text = text;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.pictureView.image != nil) {
        CGFloat left = self.detailTextLabel.origin.x;
        CGFloat top = self.timestampLabel.origin.y + self.timestampLabel.height + kTableCellMargin;
        
        self.pictureView.frame = CGRectMake(left, top, self.detailTextLabel.frame.size.width, [PictureObjItemCell pictureHeightForImage:self.pictureView.image]);
        
        CGFloat textTop = top + self.pictureView.height;
        self.detailTextLabel.frame = CGRectMake(left, textTop, self.detailTextLabel.width, [PictureObjItemCell textHeightForItem:(ManagedObjFeedItem*)_item] + kTableCellSmallMargin);
    }
}

@end
