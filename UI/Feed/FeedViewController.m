//
//  FeedViewController.m
//  musubi
//
//  Created by Willem Bult on 10/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FeedViewController.h"
#import "FeedItemTableCell.h"
#import "HTMLAppViewController.h"

@implementation FeedViewController

@synthesize feed, messages, updateField, pictureButton, updates;

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

    [self setUpdates: [[NSMutableDictionary alloc] init]];
    renderer = [[ObjRenderer alloc] init];
    
    ManagedFeed* managedFeed = [[Musubi sharedInstance] feedByName: [feed session]];
    
    [self setMessages:[NSMutableArray array]];
    for (ManagedMessage* msg in [managedFeed allMessages]) {
        [[self messages] insertObject:[msg message] atIndex:0];
    }
    
    [[Musubi sharedInstance] listenToGroup: feed withListener:self];

    [updateField setDelegate:self];

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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [messages count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0) {
        Message* msg = [self msgForIndexPath:indexPath];
        FeedItemTableCell* cell = (FeedItemTableCell*) [tableView dequeueReusableCellWithIdentifier:@"FeedItemCell"];

        [cell setItemView: [renderer renderUpdate: [self updateForMessage: msg]]];
        
        NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];

        [[cell senderLabel] setText: [[msg sender] name]];
        [[cell timestampLabel] setText:[dateFormatter stringFromDate:[msg timestamp]]];
        return cell;
    } else {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"StatusCell"];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0) {
        return [renderer renderHeightForUpdate:[self updateForMessage:[self msgForIndexPath:indexPath]]] + 73;
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

- (id<Update>) updateForMessage: (SignedMessage*) msg {
    id<Update> update = [updates objectForKey: [msg hash]];
    NSString* objType = [msg obj].type;

    if (update == nil) {
        if ([objType isEqualToString:kObjTypeJoinNotification]) 
            update = [[StatusUpdate alloc] initWithText:@"I'm here"];
        else if ([objType isEqualToString:kObjTypeStatus]) 
            update = [StatusUpdate createFromObj:[msg obj]];
        else if ([objType isEqualToString:kObjTypePicture]) 
            update = [PictureUpdate createFromObj:[msg obj]];
     
        if (update != nil)
            [updates setObject:update forKey:[msg hash]];
    }
    
    return update;
}

- (SignedMessage* ) msgForIndexPath: (NSIndexPath *)indexPath {
    return [messages objectAtIndex:([indexPath row] - 1)];
}

- (void)newMessage:(SignedMessage *)message {
    if (message != nil) {
        [messages insertObject:message atIndex:0];
    }
    
    [[self tableView] performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:FALSE];
}

- (void)pictureButtonPushed:(id)sender {
    UIImagePickerController* picker =[[UIImagePickerController alloc] init];
    [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
    [picker setDelegate:self];
    
    [self presentModalViewController:picker animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    
    PictureUpdate* update = [[PictureUpdate alloc] initWithImage: image];
    [[Musubi sharedInstance] sendObj:[update obj] forApp:kMusubiAppId toGroup:feed];
    
    [[self modalViewController] dismissModalViewControllerAnimated:YES];
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
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
    
    NSString* appId = [[self msgForIndexPath:indexPath] appId];
    if (appId == nil) {
        appId = kMusubiAppId;
    }
    
    App* app = [[App alloc] init];
    [app setName: appId];
    
    HTMLAppViewController* appViewController = (HTMLAppViewController*) [[self storyboard] instantiateViewControllerWithIdentifier:@"app"];
    [appViewController setApp: app];
    [appViewController setFeed: feed];
    
    [[self navigationController] pushViewController:appViewController animated:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField text].length > 0) {
        StatusUpdate* update = [[StatusUpdate alloc] initWithText: [textField text]];
        [[Musubi sharedInstance] sendObj:[update obj] forApp:kMusubiAppId toGroup:feed];
        [textField setText:@""];
    }
}

@end
