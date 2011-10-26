//
//  ViewController.h
//  musubi
//
//  Created by Willem Bult on 10/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GroupListViewController : UITableViewController {
    NSArray* groups;
}

@property (nonatomic, retain) NSArray* groups;

@end
