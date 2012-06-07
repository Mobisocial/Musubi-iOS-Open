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
//  FriendPickerViewController.m
//  musubi
//
//  Created by Willem Bult on 6/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FriendPickerViewController.h"
#import "FriendListDataSource.h"
#import "Three20UI/UIViewAdditions.h"
#import "FriendListItem.h"
#import "Musubi.h"

@interface FriendPickerViewController ()

@end

@implementation FriendPickerViewController

@synthesize delegate = _delegate, pinnedIdentities = _pinnedIdentities;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // TTTableViewController doesn't implement initWithCoder: so do the required init here
        _lastInterfaceOrientation = self.interfaceOrientation;
        _tableViewStyle = UITableViewStylePlain;
        _clearsSelectionOnViewWillAppear = YES;
        _flags.isViewInvalid = YES;
        _remainingImports = [NSMutableDictionary dictionaryWithCapacity:2];
        self.autoresizesForKeyboard = YES;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    UIScrollView* recipientView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 36)];
    [recipientView setUserInteractionEnabled:YES];
    [recipientView setMultipleTouchEnabled:YES];
    [recipientView addSubview:self.pickerTextField];
    [self.pickerTextField setFrame:CGRectMake(0, 0, recipientView.frame.size.width, recipientView.frame.size.height)];
    
    self.tableView.top += recipientView.height;
    self.tableView.height -= recipientView.height;
    
    [self.view addSubview:recipientView];
    
    _importingLabel = [[UILabel alloc] init];
    _importingLabel.font = [UIFont systemFontOfSize: 13.0];
    _importingLabel.text = @"";
    _importingLabel.backgroundColor = [UIColor colorWithRed:78.0/256.0 green:137.0/256.0 blue:236.0/256.0 alpha:1];
    _importingLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:_importingLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Cardinal
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:164.0/256.0 green:0 blue:29.0/256.0 alpha:1];

    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updateImporting:) name:kMusubiNotificationIdentityImported object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    
    [[Musubi sharedInstance].notificationCenter removeObserver:self name:kMusubiNotificationIdentityImported object:nil];
}

- (void) updateImporting: (NSNotification*) notification {
    if (![NSThread currentThread].isMainThread) {
        [self performSelectorOnMainThread:@selector(updateImporting:) withObject:notification waitUntilDone:NO];
        return;
    }    
    
    if ([notification.object objectForKey:@"index"]) {
        NSNumber* index = [notification.object objectForKey:@"index"];
        NSNumber* total = [notification.object objectForKey:@"total"];
        
        [_remainingImports setObject:[NSNumber numberWithInt:total.intValue - index.intValue - 1] forKey:[notification.object objectForKey:@"type"]];
        
        int remaining = 0;
        for (NSNumber* rem in _remainingImports.allValues) {
            remaining += rem.intValue;
        }
        
        if (remaining > 0) {
            [_importingLabel setText:[NSString stringWithFormat: @"  Importing %d contacts...", remaining]];
            [_importingLabel setFrame:CGRectMake(0, 386, 320, 30)];
        } else {
            _importingLabel.text = @"";
            [_importingLabel setFrame:CGRectZero];    
        }
        
        if (remaining % 20 == 0) {
            [self search: _pickerTextField.text];
        }
    }
}

- (void)createModel {
    self.dataSource = [[FriendListDataSource alloc] init];
    ((FriendListDataSource*)self.dataSource).pinnedIdentities = _pinnedIdentities;
}

- (id<UITableViewDelegate>)createDelegate {
    return [[FriendPickerTableViewDelegate alloc] initWithController:self];
}

- (TTPickerTextField*) pickerTextField {
    if (_pickerTextField == nil) {
        _pickerTextField = [[TTPickerTextField alloc] init];
        _pickerTextField.delegate = self;
        _pickerTextField.dataSource = self;
        _pickerTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        _pickerTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _pickerTextField.rightViewMode = UITextFieldViewModeAlways;
        _pickerTextField.returnKeyType = UIReturnKeyDone;
        _pickerTextField.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        _pickerTextField.font = [UIFont systemFontOfSize:14.0];
    }
    
    return _pickerTextField;
}

- (void)search:(NSString *)text {
    [self.dataSource search:text];
    [self.tableView reloadData];
}

- (void)textField:(TTPickerTextField *)textField didAddCellAtIndex:(NSInteger)index {
    FriendListDataSource* ds = (FriendListDataSource*)self.dataSource;
    FriendListItem* item = [textField.cells objectAtIndex: index];
    [ds toggleSelectionForItem:item];
    
    NSIndexPath* path = [ds indexPathForItem:item];
    if (path != nil)
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationNone];
    
    if (textField.lineCount > 1) {
        [textField setFrame:CGRectMake(0, 0, 320, 30 * textField.lineCount + 6)];
        
        [textField.superview setFrame:CGRectMake(0, 0, 320, 70)];
        [self.tableView setFrame:CGRectMake(0, 70, 320, 362)];
        
        int newY = 30 * (textField.lineCount - 2);
        [((UIScrollView*)textField.superview) setContentOffset:CGPointMake(0, newY) animated:NO];
    }
}

- (void) textField: (UITextField*)tf didRemoveCellAtIndex: (int) idx {
    FriendListDataSource* ds = (FriendListDataSource*)self.dataSource;
    FriendListItem* item = [ds.selection objectAtIndex: idx];
    [ds toggleSelectionForItem:item];
    
    NSIndexPath* path = [ds indexPathForItem:item];
    if (path != nil)
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:path] withRowAnimation:UITableViewRowAnimationNone];
}

- (NSString*) tableView:(UITableView*)tv labelForObject:(id) obj {
    return ((FriendListItem*) obj).musubiName;
}

- (IBAction)friendsSelected:(id)sender {
    FriendListDataSource* ds = (FriendListDataSource*)self.dataSource;
    [_delegate friendsSelected:ds.selectedIdentities];
}

@end

@implementation FriendPickerTableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    FriendListDataSource* ds = (FriendListDataSource*)self.controller.dataSource;
    FriendListItem* item = [ds itemAtIndexPath: indexPath];
    
    if (!item.pinned) {
        TTPickerTextField* picker = ((FriendPickerViewController*)self.controller).pickerTextField;
        
        if (!item.selected) {
            [picker addCellWithObject: item];
        } else {
            [picker removeCellWithObject: item];
        }
    }
}


@end