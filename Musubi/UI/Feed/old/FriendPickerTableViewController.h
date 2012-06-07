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

@protocol FriendPickerDelegate <NSObject>
- (void) friendsSelected:(NSArray*)selection;
@end

@interface FriendPickerTableViewController : UIViewController<UITableViewDelegate, UITextFieldDelegate> {
   
    IBOutlet UIScrollView* recipientView;
    IBOutlet UITableView* tableView;
    
    TTPickerTextField* pickerTextField;
    
    UILabel* importingLabel;
    NSMutableDictionary* remainingImports;
}

@property (nonatomic, strong) IdentityManager* identityManager;
@property (nonatomic, strong) NSMutableDictionary* identities;
@property (nonatomic, strong) NSArray* index;
@property (nonatomic, strong) NSMutableArray* selection;
@property (nonatomic, strong) id<FriendPickerDelegate> delegate;
@property (nonatomic, strong) NSSet* pinnedIdentities;
@end

@interface FriendPickerTableViewCell : UITableViewCell {
    IBOutlet UIImageView* imageView;
    IBOutlet UILabel* textLabel;
    IBOutlet UILabel* detailTextLabel;
}

@end