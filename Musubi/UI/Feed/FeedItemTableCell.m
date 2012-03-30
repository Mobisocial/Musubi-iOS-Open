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
//  FeedItemTableCell.m
//  musubi
//
//  Created by Willem Bult on 11/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FeedItemTableCell.h"

@implementation FeedItemTableCell

@synthesize itemView, senderLabel, timestampLabel, profilePictureView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setItemView:(UIView *)iv {
    
    itemView = nil;
    [itemView release];
    
    itemView = [iv retain];
    CGRect itemViewFrame = [itemView frame];
    itemViewFrame.origin.x = 0; itemViewFrame.origin.y = 0;
    [itemView setFrame:itemViewFrame];
    if ([[itemContainerView subviews] count] > 0)
        [[[itemContainerView subviews] objectAtIndex:0] removeFromSuperview];
    
    [itemContainerView addSubview: itemView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [profilePictureView setFrame: CGRectMake(5, 5, 36, 36)];
    
    CGRect itemContainerViewFrame = [itemContainerView frame];
    itemContainerViewFrame.size.height = [itemView frame].size.height + [itemView frame].origin.y;
    itemContainerViewFrame.size.width = [itemView frame].size.width + [itemView frame].origin.x;
    [itemContainerView setFrame:itemContainerViewFrame];
    
/*    CGRect myFrame = [self frame];
    myFrame.size.height = 30 + [itemContainerView frame].size.height;
    [self setFrame:myFrame];*/
    /*
    CGRect timestampLabelFrame = [timestampLabel frame];
    timestampLabelFrame.origin.y = [itemContainerView frame].size.height + [itemContainerView frame].origin.y + 9;
    [timestampLabel setFrame:timestampLabelFrame];    */
}


@end
