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
@implementation OutlineTextLabel
@synthesize strokeWidth = _strokeWidth;
@synthesize strokeColor = _strokeColor;

-(id)init
{
    if((self = [super init]))
    {
        _strokeWidth = kDefaultStrokeWidth;
        _strokeColor = [UIColor blackColor];
    }
    
    return self;
}
-(void)drawTextInRect:(CGRect)rect
{
    [super drawTextInRect:rect];
    
    CGSize shadowOffset = self.shadowOffset;
    UIColor* textColor = self.textColor;
    BOOL highlighted = self.highlighted;
    
    CGContextRef c = UIGraphicsGetCurrentContext();
    
    // Draw the stroke
    if( _strokeWidth > 0 )
    {
        CGContextSetLineWidth(c, _strokeWidth);
        CGContextSetTextDrawingMode(c, kCGTextStroke);
        
        self.textColor = _strokeColor;
        self.shadowColor = _strokeColor;
        self.shadowOffset = CGSizeMake(0, 0);
        self.highlighted = NO;
        
        [super drawTextInRect:rect];
    }
    
    // Revert to the original UILabel Params
    self.highlighted = highlighted;
    self.textColor = textColor;
    
    // If we need to draw with stroke, we're gonna have to rely on the shadow
    if(_strokeWidth > 0)
    {
        self.shadowOffset = CGSizeMake(0, 1); // Yes. It's inverted.
    }
    
    // Now we can draw the actual text
    CGContextSetTextDrawingMode(c, kCGTextFill);
    [super drawTextInRect:rect];
    
    // Revert to the original Shadow Offset
    self.shadowOffset = shadowOffset;
}
@end

@implementation FeedListItemCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.titleLabel.font = [UIFont boldSystemFontOfSize:14.0];
    }
    return self;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self profilePictureView];
    _profilePictureView.contentMode = UIViewContentModeScaleAspectFit;
    _profilePictureView.frame = CGRectMake(0, 0, kDefaultMessageImageWidth, kDefaultMessageImageHeight);
    
    [self pictureView];
    _pictureView.contentMode = UIViewContentModeScaleAspectFill;
    _pictureView.clipsToBounds = YES;
    _pictureView.frame = CGRectMake(kDefaultMessageImageWidth, 0, self.frame.size.width - kDefaultMessageImageWidth, kDefaultMessageImageHeight);
    
    [_unreadLabel sizeToFit];
    _unreadLabel.left = self.contentView.width - _unreadLabel.width - kTableCellSmallMargin;
    _unreadLabel.top = kTableCellSmallMargin + _timestampLabel.height + kTableCellSmallMargin;

    [self timestampLabel];
    int left = _profilePictureView.right + kTableCellSmallMargin;
    int width = _timestampLabel.left - left - kTableCellMargin;
    
    _titleLabel.left = left;
    _titleLabel.width = width;
    _bubbleLabel.frame = _titleLabel.frame;
    
    [self stripeView];
    _stripeView.frame = _pictureView.frame;
    _stripeView.height = _bubbleLabel.bottom;
    self.textLabel.left = left;
    self.textLabel.width = width;
    self.detailTextLabel.left = left;
    self.detailTextLabel.width = _unreadLabel.left - left - kTableCellMargin;
    
}


- (void)setObject:(FeedListItem*)object {
    [super setObject:object];
    NSString* unread = @"";
    if (object.unread > 0) {
        unread = [NSString stringWithFormat:@"%d new", object.unread];
    }
    self.unreadLabel.text = unread;
    if(object.picture) {
        self.titleLabel.hidden = YES;
        self.detailTextLabel.hidden = YES;
        self.timestampLabel.hidden = YES;
        self.bubbleLabel.hidden = NO;
        self.bubbleLabel.text = object.title;
        self.pictureView.hidden = NO;
        self.stripeView.hidden = NO;
        self.pictureView.image = object.picture;
    } else {
        self.detailTextLabel.hidden = NO;
        self.titleLabel.hidden = NO;
        self.timestampLabel.hidden = NO;
        self.bubbleLabel.hidden = YES;
        self.pictureView.image = nil;
        self.stripeView.hidden = YES;
        self.pictureView.hidden = YES;
    }
    self.profilePictureView.image = object.image;
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

- (UILabel*)bubbleLabel {
    if (!_bubbleLabel) {
        _bubbleLabel = [[OutlineTextLabel alloc] init];
        _bubbleLabel.font = [UIFont boldSystemFontOfSize:14.0];
        _bubbleLabel.backgroundColor = [UIColor clearColor];
        _bubbleLabel.strokeColor = [UIColor blackColor];
        _bubbleLabel.strokeWidth = 0;
        _bubbleLabel.textColor = [UIColor whiteColor];
        _bubbleLabel.clipsToBounds = YES;
        _bubbleLabel.userInteractionEnabled = YES;        
        _bubbleLabel.opaque = NO;
        [self.contentView addSubview:_bubbleLabel];
    }
    return _bubbleLabel;
    
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
- (UIImageView*)stripeView {
    if (!_stripeView) {
        _stripeView = [[UIView alloc] init];
        _stripeView.backgroundColor = [UIColor colorWithWhite:0 alpha:.55];
        _stripeView.opaque = NO;
        [self.contentView insertSubview:_stripeView atIndex:1];
    }
    return _stripeView;
}

+ (CGFloat)tableView:(UITableView *)tableView rowHeightForObject:(id)object {
    return 70;
}

@end
