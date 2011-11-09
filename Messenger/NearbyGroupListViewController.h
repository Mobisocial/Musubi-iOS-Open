//
//  NearbyGroupListViewController.h
//  musubi
//
//  Created by Willem Bult on 10/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GroupProvider.h"
#import "GPSNearbyGroups.h"
#import "FeedViewController.h"
#import "Musubi.h"

@interface NearbyGroupListViewController : UITableViewController {
    NSArray* groups;
}

@property (nonatomic, retain) NSArray* groups;

@end
