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
//  SettingsViewController.m
//  musubi
//
//  Created by Willem Bult on 1/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SettingsViewController.h"
#import "AppDelegate.h"
#import "FacebookAuth.h"
#import "MAccount.h"
#import "Musubi.h"

@implementation SettingsViewController

@synthesize authMgr, accountTypes;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setAuthMgr:[[AccountAuthManager alloc] initWithDelegate:self]];
    [self setAccountTypes: [NSDictionary dictionaryWithObjectsAndKeys:@"Facebook", kAccountTypeFacebook, nil]];
    
    for (NSString* type in accountTypes.allKeys) {
        [authMgr performSelectorInBackground:@selector(checkStatus:) withObject:type];
        [authMgr checkStatus: type];
    }

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [self setAuthMgr: nil];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)pictureClicked:(id)sender {    
    UIImagePickerController* picker = [[[UIImagePickerController alloc] init] autorelease];
    [picker setSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
    [picker setDelegate:self];
    
    [self presentModalViewController:picker animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return 1;
        case 1:
            return accountTypes.count;
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
    switch (section) {
        case 0:
            return @"Profile";
        case 1:
            return @"Networks";
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            NamePictureCell* cell = (NamePictureCell*) [tableView dequeueReusableCellWithIdentifier:@"NamePictureCell"];
            return cell;
        }
        case 1: {
            UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
            if (cell == nil) {
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"] autorelease];
            }
            
            NSString* accountType = [accountTypes.allKeys objectAtIndex:indexPath.row];
            NSString* account = [accountTypes objectForKey:accountType];
            [[cell textLabel] setText: account];
            [[cell detailTextLabel] setText: [authMgr isConnected:accountType] ? @"Connected" : @"Click to connect"];
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

            return cell;
        }
    }
    
    /*
    User* user = [[Identity sharedInstance] user];
    if ([user picture] != nil) {
        
        UIButton* button = [cell picture];
        [button setImage:[UIImage imageWithData:[user picture]] forState:UIControlStateNormal];
    }
    [[cell nameTextField] setText: [user name]];*/
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: {
            return 90;
        }
        default: {
            return 44;
        }
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
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[ alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.<#DetailViewController#>
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
    
    switch (indexPath.section) {
        case 0:{
            break;
        }
        case 1: {
            NSString* accountType = [accountTypes.allKeys objectAtIndex:indexPath.row];
            if (![authMgr isConnected: accountType]) {
                [authMgr performSelectorInBackground:@selector(connect:) withObject:accountType];
            } else {
                // Debug notification

                [[Musubi sharedInstance].notificationCenter postNotification:[NSNotification notificationWithName:kMusubiNotificationFacebookFriendRefresh object:nil]];
            }
            
            break;
        }
    }
}

#pragma mark - AccountAuthManager delegate

- (void)accountWithType:(NSString *)type isConnected:(BOOL)connected {
    int row = [accountTypes.allKeys indexOfObject:type];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
}


#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    /*
    if ([textField text].length > 0) {
        [[[Identity sharedInstance] user] setName: [textField text]];
    } else {
        [[[Identity sharedInstance] user] setName: [[UIDevice currentDevice] name]];   
    }
    
    [[Identity sharedInstance] saveUser];
    [[self tableView] reloadData];*/
}

#pragma mark - Image picker delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    /*
    User* user = [[Identity sharedInstance] user];
    
    double scale = MIN(1, 256 / MAX([image size].width, [image size].height));
    if (scale < 1) {
        CGSize newSize = CGSizeMake([image size].width * scale, [image size].height * scale);
        image = [image resizedImage:newSize interpolationQuality:0.9];
        [user setPicture: UIImageJPEGRepresentation(image, 0.99)];
    }
    
    [[Identity sharedInstance] saveUser];
    
    [[self tableView] reloadData];
    [[self modalViewController] dismissModalViewControllerAnimated:YES];*/
}

@end

