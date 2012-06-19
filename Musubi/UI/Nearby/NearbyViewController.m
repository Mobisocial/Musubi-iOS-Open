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
//  NearbyViewController.m
//  musubi
//
//  Created by MokaFive User on 6/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NearbyViewController.h"
#import "NearbyFeedCell.h"
#import "NearbyFeed.h"
#import "GpsScanner.h"
#import "DejalActivityView.h"

@interface NearbyViewController ()

@end

@implementation NearbyViewController
@synthesize password;
@synthesize table;
@synthesize nearbyFeeds;

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
    [self passwordChanged:nil];
}

- (void)viewDidUnload
{
    [self setPassword:nil];
    [self setTableView:nil];
    [self setTable:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return nearbyFeeds.count > 0 ? 1 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#warning Incomplete method implementation.
    // Return the number of rows in the section.
    return nearbyFeeds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"NearbyFeedCell";
    NearbyFeedCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    NearbyFeed* item = [nearbyFeeds objectAtIndex:indexPath.row];
    if(cell.thumbnail)
        cell.thumbnail.image = [UIImage imageWithData:item.thumbnail];
    else 
        cell.thumbnail.image = [UIImage imageNamed:@"missing.png"];
    
    cell.sharerName.text = item.sharerName;
    cell.groupName.text = item.groupName;
    return cell;
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
    NSString* groupName = @"Group Name";

    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Join Conversation" message:[NSString stringWithFormat:@"Would you like to join the conversation \"%@\"?", groupName]  delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];

    [alert show];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex == 0)
        return;
    
    //TODO: join the group
    [self.navigationController popViewControllerAnimated:YES];
        
}

- (IBAction)refresh:(id)sender {
    [DejalBezelActivityView activityViewForView:self.tableView withLabel:@"Identifying Location" width:200];
    GpsScanner* scanner = [[GpsScanner alloc] init];
    [scanner scanForNearbyWithPassword:password.text onSuccess:^(NSArray *nearby) {
        [DejalBezelActivityView removeViewAnimated:YES];
        nearbyFeeds = nearby;
        NSLog(@"nearby: %@", nearbyFeeds);
        [table reloadData];
    } onFail:^(NSError *error) {
        [DejalBezelActivityView removeViewAnimated:YES];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nearby" 
                                                        message:[NSString stringWithFormat:@"Unable to find conversations nearby, %@", error] 
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [table reloadData];
        [alert show]; 
        
    }];
}

- (IBAction)passwordChanged:(id)sender {
    GpsScanner* scanner = [[GpsScanner alloc] init];
    [scanner scanForNearbyWithPassword:password.text onSuccess:^(NSArray *nearby) {
        nearbyFeeds = nearby;
        NSLog(@"nearby: %@", nearbyFeeds);
        [table reloadData];
    } onFail:^(NSError *error) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nearby" 
                                                        message:[NSString stringWithFormat:@"Unable to find conversations nearby, %@", error] 
                                                       delegate:nil 
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        nearbyFeeds = nil;
        [table reloadData];
        [alert show]; 
        
    }];
}
@end
