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
//  FeedListItemCell.m
//  musubi
//
//  Created by Willem Bult on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedListItemCell.h"
#import "FeedListItem.h"
#import "MFeed.h"
#import "Three20UI/UIViewAdditions.h"

static const CGFloat    kDefaultMessageImageWidth   = 70.0f;
static const CGFloat    kDefaultMessageImageHeight  = 70.0f;

static NSUInteger kDefaultStrokeWidth = 1;
@implementation FeedListItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
        self.userInteractionEnabled = YES;

    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self profilePictureView];
    _profilePictureView.contentMode = UIViewContentModeScaleAspectFit;
    _profilePictureView.frame = CGRectMake(0, 0, kDefaultMessageImageWidth, kDefaultMessageImageHeight);
    
    [_unreadLabel sizeToFit];
    _unreadLabel.left = self.contentView.width - _unreadLabel.width - kTableCellSmallMargin;
    _unreadLabel.top = kTableCellSmallMargin + _timestampLabel.height + kTableCellSmallMargin;

    [self timestampLabel];
    int left = _profilePictureView.right + kTableCellSmallMargin;
    int width = _timestampLabel.left - left - kTableCellMargin;
    
    _titleLabel.left = left;
    _titleLabel.width = width;
    self.textLabel.left = left;
    self.textLabel.width = width;
    self.detailTextLabel.left = left;
    self.detailTextLabel.width = _unreadLabel.left - left - kTableCellMargin;
    self.timestampLabel.backgroundColor = [UIColor clearColor];
    self.timestampLabel.opaque = NO;
    
    [self pictureView];
    _pictureView.contentMode = UIViewContentModeScaleAspectFit;
    _pictureView.clipsToBounds = YES;
    _pictureView.frame = CGRectMake(left, self.detailTextLabel.top, self.frame.size.width - kDefaultMessageImageWidth, self.detailTextLabel.height);
    

}


- (void)setObject:(FeedListItem*)object {
    [super setObject:object];
    NSString* unread = @"";
    if (object.unread > 0) {
        unread = [NSString stringWithFormat:@"%d new", object.unread];
    }
    self.unreadLabel.text = unread;
    self.titleLabel.text = object.title;
    
    if (object.special) {
        self.detailTextLabel.font = [UIFont italicSystemFontOfSize:14.0];
    } else {
        self.detailTextLabel.font = [UIFont systemFontOfSize:14.0];
    }
    
    self.profilePictureView.image = object.image;
    self.selectionStyle = UITableViewCellSelectionStyleGray;
}

- (UILabel*)unreadLabel {
    if (!_unreadLabel) {
        _unreadLabel = [[UILabel alloc] init];
        _unreadLabel.font = [UIFont boldSystemFontOfSize:14.0];
        _unreadLabel.textColor = [UIColor redColor];
        _unreadLabel.backgroundColor = [UIColor clearColor];
        _unreadLabel.userInteractionEnabled = YES;        
        [self.contentView addSubview:_unreadLabel];
    }
    return _unreadLabel;
}


- (UIImageView*)profilePictureView {
    if (!_profilePictureView) {
        _profilePictureView = [[UIImageView alloc] init];
        [self.contentView addSubview:_profilePictureView];
    }
    return _profilePictureView;
}
- (UIImageView*)pictureView {
    if (!_pictureView) {
        _pictureView = [[UIImageView alloc] init];
        _pictureView.autoresizingMask = UIViewAutoresizingNone;
        [self.contentView insertSubview:_pictureView atIndex:0];

    }
    return _pictureView;
}

+ (CGFloat)tableView:(UITableView *)tableView rowHeightForObject:(id)object {
    return 70;
}

@end
