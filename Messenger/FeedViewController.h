//
//  FeedViewController.h
//  musubi
//
//  Created by Willem Bult on 10/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Feed.h"

@interface FeedViewController : UITableViewController {
    Feed* feed;
}

@property (nonatomic,retain) Feed* feed;

@end
