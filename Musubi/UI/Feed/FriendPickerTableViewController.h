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
//  FriendPickerTableViewController.h
//  Musubi
//
//  Created by Willem Bult on 3/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Three20/Three20.h"

@class IdentityManager, MIdentity;

@interface FriendPickerTableViewController : UIViewController<UITableViewDelegate, UITableViewDataSource, TTTableViewDataSource, UITextFieldDelegate> {
    IdentityManager* _identityManager;
    NSMutableDictionary* _identities;
    NSArray* _index;
    NSMutableArray* _selection;
    
    IBOutlet UIScrollView* recipientView;
    IBOutlet UITableView* tableView;
    
    TTPickerTextField* pickerTextField;
}

@property (nonatomic) IdentityManager* identityManager;
@property (nonatomic) NSMutableDictionary* identities;
@property (nonatomic) NSArray* index;
@property (nonatomic) NSMutableArray* selection;

- (IBAction) createFeed: (id) sender;

@end

@interface FriendPickerTableViewCell : UITableViewCell {
    IBOutlet UIImageView* imageView;
    IBOutlet UILabel* textLabel;
    IBOutlet UILabel* detailTextLabel;
}

@end