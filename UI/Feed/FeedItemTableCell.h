//
//  FeedItemTableCell.h
//  musubi
//
//  Created by Willem Bult on 11/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FeedItemTableCell : UITableViewCell {
@private
    IBOutlet UILabel* senderLabel;
    IBOutlet UILabel* timestampLabel;
    IBOutlet UIView* itemContainerView;
    IBOutlet UIView* itemView;
}

@property (nonatomic,retain) IBOutlet UILabel* senderLabel;
@property (nonatomic,retain) IBOutlet UILabel* timestampLabel;
@property (nonatomic,retain) UIView* itemView;

@end
