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
//  FeedSettingsViewController.m
//  musubi
//
//  Created by Ian Vo on 6/1/12.
//  Copyright (c) 2012 Stanford University. All rights reserved.
//

#import "FeedSettingsViewController.h"
#import "FriendPickerTableViewController.h"
#import "FeedNameCell.h"
#import "FeedManager.h"
#import "MFeed.h"
#import "Musubi.h"
#import "FeedNameObj.h"
#import "AppManager.h"
#import "ObjHelper.h"

@interface FeedSettingsViewController ()

@end

@implementation FeedSettingsViewController

@synthesize feed = _feed;
@synthesize feedManager = _feedManager;
@synthesize delegate = _delegate;

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    
    if (self) {
        _feedManager = [[FeedManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    }
    
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
    switch (section) {
        case 0:
            return @"Conversation Title";
        case 1:
            return @"Actions";    
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    switch (section) {
        case 0:
            return 1;
        case 1:
            return 2;
    }
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            static NSString *cellIdentifier = @"FeedNameCell";
            //FeedNameCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc]
                        initWithStyle:UITableViewCellStyleValue2 
                        reuseIdentifier:cellIdentifier];
            }
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            cell.detailTextLabel.text = @"Title";
            UITextField *textField;
            
            textField = [[UITextField alloc] initWithFrame:CGRectMake(90,
                                                                      tableView.rowHeight / 2 - 10, 200, 20)];
            textField.borderStyle = UITextBorderStyleNone;
            textField.textColor = [UIColor blackColor];
            textField.font = [UIFont systemFontOfSize:14];
            textField.placeholder = @"Conversation Title";
            textField.text = [_feedManager identityStringForFeed: _feed];
            textField.backgroundColor = [UIColor clearColor];
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            textField.keyboardType = UIKeyboardTypeDefault;
            textField.returnKeyType = UIReturnKeyDone;
            textField.tag = indexPath.row;
            textField.delegate = self;
            
            [cell.contentView addSubview:textField];
            
            return cell;
        }
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    static NSString *cellIdentifier = @"MembersCell";
                    //FeedNameCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    if (cell == nil) {
                        cell = [[UITableViewCell alloc]
                                initWithStyle:UITableViewCellStyleValue2 
                                reuseIdentifier:cellIdentifier];
                    }
                    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                    cell.detailTextLabel.text = @"Members";
                    
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    //[cell.contentView addSubview:textField];
                    
                    return cell;
                }
                case 1: {
                    static NSString *cellIdentifier = @"NearbyCell";                    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
                    if (cell == nil) {
                        cell = [[UITableViewCell alloc]
                                initWithStyle:UITableViewCellStyleValue2 
                                reuseIdentifier:cellIdentifier];
                    }
                    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                    cell.detailTextLabel.text = @"Nearby";
                    
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    //[cell.contentView addSubview:textField];
                    
                    return cell;
                }
            }
        }
    }
    
    return nil;
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"AddPeopleSegue"]) {
        FriendPickerTableViewController *vc = segue.destinationViewController;
        FeedManager* fm = [[FeedManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
        vc.pinnedIdentities = [NSSet setWithArray:[fm identitiesInFeed:_feed]];
        vc.delegate = _delegate;
    }
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    switch (indexPath.section) {
        case 0: {
            break;
        }
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    [self performSegueWithIdentifier:@"AddPeopleSegue" sender:_feed];
                    break;
                }
                case 1: {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nearby" 
                                                                    message:@"Nobody is near you because nobody loves you." 
                                                                   delegate:nil 
                                                          cancelButtonTitle:@"My life is sad."
                                                          otherButtonTitles:nil];
                    [alert show];
                }
            }
        }
    }
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSString* name = textField.text;
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if(!name || !name.length || [name isEqualToString:[_feedManager identityStringForFeed: _feed]])
        return;
    
    FeedNameObj* name_change = [[FeedNameObj alloc] initWithName:name];
    
    AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    MApp* app = [am ensureSuperApp];
    
    [ObjHelper sendObj:name_change toFeed:_feed fromApp:app usingStore:[Musubi sharedInstance].mainStore];
    
    [_delegate changedName:name];
}

@end
