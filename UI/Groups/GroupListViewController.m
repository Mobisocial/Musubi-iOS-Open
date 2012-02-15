//
//  ViewController.m
//  musubi
//
//  Created by Willem Bult on 10/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GroupListViewController.h"
#import "Download.h"
#import "GPSNearbyGroups.h"
#import "GroupProvider.h"
#import "HTMLAppViewController.h"

@implementation GroupListViewController
@synthesize joinedGroups, nearbyGroups, gps;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    [self setTitle: @"Groups"];
    [self setJoinedGroups: [[Musubi sharedInstance] groups]];
    [self setNearbyGroups: [NSArray array]];

    [self setGps: [[[GPSNearbyGroups alloc] init] autorelease]];    
    [gps setDelegate: self];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)updatedGroups:(NSArray *)groups {
    [self setNearbyGroups:groups];
    [self.tableView reloadData];
}

- (Feed*) feedForIndexPath: (NSIndexPath*) indexPath {
    Feed* group = nil;
    
    if (indexPath.section == 0)
        group = [joinedGroups objectAtIndex: indexPath.row];
    else
        group = [nearbyGroups objectAtIndex: indexPath.row];

    return group;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"My Groups";
    } else if (section == 1) {
        return @"Nearby Groups";
    } else {
        return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0 && [joinedGroups count] == 0) {
        return @"You're not participating in any groups yet.";
    } else if (section == 1 && [nearbyGroups count] == 0) {
        return @"No broadcasting groups found nearby.";
    } else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [joinedGroups count];
    } else if (section == 1) {
        return [nearbyGroups count];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    [cell setEditing:YES];

    Feed* group = [self feedForIndexPath:indexPath];
    cell.textLabel.text = [group name];    
    return cell;
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    Feed* group = nil;
    
    if ((alertView.tag == ALERT_VIEW_JOIN) && buttonIndex == 1) {        
        group = [self feedForIndexPath:[[self tableView] indexPathForSelectedRow]];
    } else if (alertView.tag == ALERT_VIEW_NEW && buttonIndex == 1) {
        NSString* title = [alertView textFieldAtIndex:0].text;
        if ([title length] > 0) {
            group = [GroupFeed createWithTitle:title];
        } else {
            [[[[UIAlertView alloc] initWithTitle:@"Oops" message:@"Cannot create a group with an empty name" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] autorelease] show];
        }
    }
    
    if (group != nil) {
        [[Musubi sharedInstance] joinGroup: group];
        [self setJoinedGroups: [[Musubi sharedInstance] groups]];
        [self.tableView reloadData];
        
        NSLog(@"Group: %@", group);
        FeedViewController* feedViewController = (FeedViewController*) [[self storyboard] instantiateViewControllerWithIdentifier:@"feed"];
        [feedViewController setFeed: group];
        [[self navigationController] pushViewController:feedViewController animated:YES];
    }
    
    [[self tableView] deselectRowAtIndexPath:[[self tableView] indexPathForSelectedRow] animated:NO];
}

- (void)newGroupButtonClicked:(id)sender {
    UIAlertView* newGroupName = [[[UIAlertView alloc] initWithTitle:@"New group" message:@"Please name the new group" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Ok", nil] autorelease];
    [newGroupName setTag:ALERT_VIEW_NEW];
    [newGroupName setAlertViewStyle:UIAlertViewStylePlainTextInput];
    
    [newGroupName show];
}

#pragma mark - Table view delegate

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath 
{
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0){
        Feed* feed = [self feedForIndexPath:indexPath];
        FeedViewController* feedViewController = (FeedViewController*) [[self storyboard] instantiateViewControllerWithIdentifier:@"feed"];
        [feedViewController setFeed: feed];
        [[self navigationController] pushViewController:feedViewController animated:YES];
        
    } else if (indexPath.section == 1) {
        Feed* feed = [self feedForIndexPath:indexPath];
        UIAlertView* confirm = [[[UIAlertView alloc] initWithTitle:@"Join group" message:[NSString stringWithFormat:@"Join group %@?", [feed name]] delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil] autorelease];        
        [confirm setTag:ALERT_VIEW_JOIN];
        [confirm show];
    }
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.section == 0);
}


- (void)scopeSelectorTouched:(id)sender {
    [[self tableView] reloadData];
}

@end
