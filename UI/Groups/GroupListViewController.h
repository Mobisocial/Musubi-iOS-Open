//
//  ViewController.h
//  musubi
//
//  Created by Willem Bult on 10/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObjectStore.h"
#import "FeedViewController.h"
#import "GPSNearbyGroups.h"
#import "NSData+Crypto.h"
#import "NSData+Base64.h"

#define ALERT_VIEW_JOIN 0
#define ALERT_VIEW_NEW 1

@interface GroupListViewController : UITableViewController<UIAlertViewDelegate, GPSNearbyGroupsDelegate> {
    IBOutlet UISegmentedControl* scopeSelector;

@private
    
    NSArray* joinedGroups;
    NSArray* nearbyGroups;
    
    GPSNearbyGroups* gps;
}


@property (nonatomic, retain) NSArray* joinedGroups;
@property (nonatomic, retain) NSArray* nearbyGroups;
@property (nonatomic, retain) GPSNearbyGroups* gps;

- (Feed*) feedForIndexPath: (NSIndexPath*) indexPath;
- (IBAction) newGroupButtonClicked: (id)sender;

@end
