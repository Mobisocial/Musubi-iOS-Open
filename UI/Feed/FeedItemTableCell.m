//
//  FeedItemTableCell.m
//  musubi
//
//  Created by Willem Bult on 11/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FeedItemTableCell.h"

@implementation FeedItemTableCell

@synthesize itemView, senderLabel, timestampLabel;

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
    
    CGRect itemContainerViewFrame = [itemContainerView frame];
    itemContainerViewFrame.size.height = [itemView frame].size.height + [itemView frame].origin.y;
    itemContainerViewFrame.size.width = [itemView frame].size.width + [itemView frame].origin.x;
    [itemContainerView setFrame:itemContainerViewFrame];
    
    CGRect myFrame = [self frame];
    myFrame.size.height = 72 + [itemContainerView frame].size.height;
    [self setFrame:myFrame];
    
    CGRect timestampLabelFrame = [timestampLabel frame];
    timestampLabelFrame.origin.y = [itemContainerView frame].size.height + [itemContainerView frame].origin.y + 9;
    [timestampLabel setFrame:timestampLabelFrame];    
}


@end
