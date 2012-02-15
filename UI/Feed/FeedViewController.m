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

@synthesize feed;

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

- (void) displayMessage:(SignedMessage*) message
{
    NSString* parent = [message parentHash];
    if (parent != nil) {
        for (int i=0; i<[messages count]; i++) {
            SignedMessage* curMsg = (SignedMessage*)[messages objectAtIndex:i];
            if (curMsg != nil && [curMsg belongsToHash:parent]) {
                [messages replaceObjectAtIndex:i withObject:message];
            }
        }
    } else {
        [messages insertObject:message atIndex:0];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:[feed name]];

    cellHeights = [[NSMutableDictionary alloc] init];
    updates = [[NSMutableDictionary alloc] init];
    renderer = [[ObjRenderer alloc] init];

    messages = [[NSMutableArray alloc] init];
    
    for (ManagedMessage* msg in [[[Musubi sharedInstance] feedByName: [feed name]] allMessages]) {
        [self displayMessage:[msg message]];
    }
    [[self tableView] performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:FALSE];

    [[Musubi sharedInstance] listenToGroup: feed withListener:self];

    [updateField setDelegate:self];
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

        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        [cell setItemView: [renderer renderUpdate: [self updateForMessage: msg]]];
        
        NSDateFormatter* dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];

        [[cell senderLabel] setText: [[msg sender] name]];
        [[cell timestampLabel] setText:[dateFormatter stringFromDate:[msg timestamp]]];
        
        if ([[cell itemView] isKindOfClass:[UIWebView class]]) {
            UIWebView* webView = (UIWebView*) [cell itemView];
            if ([webView delegate] == nil) {
                [webView setTag:[indexPath row]];
                [webView setDelegate:self];
            }
        }
        
        return cell;
    } else {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"StatusCell"];
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0) {
        NSNumber* storedHeight = [cellHeights objectForKey:[NSNumber numberWithInteger:[indexPath row]]];
        if (storedHeight != nil) {
            return [storedHeight floatValue] + 73;
        }
        
        return [renderer renderHeightForUpdate:[self updateForMessage:[self msgForIndexPath:indexPath]]] + 73;
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *output = [webView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight"];
    NSNumber* height = [NSNumber numberWithInt:[output intValue]];
    [cellHeights setObject:height forKey:[NSNumber numberWithInteger:[webView tag]]];
    
    CGRect frame = [webView frame];
    [webView setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, [height floatValue])];
    
    [[self tableView] beginUpdates];
    [[self tableView] setNeedsLayout];
    [[self tableView] endUpdates];
}

- (id<Update>) updateForMessage: (SignedMessage*) msg {
    id<Update> update = [updates objectForKey: [msg hash]];
    NSString* objType = [msg obj].type;

    if (update == nil) {
        if ([objType isEqualToString:kObjTypeJoinNotification]) 
            update = [[[StatusUpdate alloc] initWithText:@"I'm here"] autorelease];
        else if ([objType isEqualToString:kObjTypeStatus]) 
            update = [StatusUpdate createFromObj:[msg obj]];
        else if ([objType isEqualToString:kObjTypePicture]) 
            update = [PictureUpdate createFromObj:[msg obj]];
        else if ([objType isEqualToString:kObjTypeAppState]) 
            update = [AppStateUpdate createFromObj:[msg obj]];
     
        if (update != nil)
            [updates setObject:update forKey:[msg hash]];
    }
    
    return update;
}

- (SignedMessage* ) msgForIndexPath: (NSIndexPath *)indexPath {
    if ([indexPath row] > 0)
        return [messages objectAtIndex:([indexPath row] - 1)];
    else
        return nil;
}

- (void)newMessage:(SignedMessage *)message {
    if (message != nil) {
        [self displayMessage:message];
        [[self tableView] performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:FALSE];
    }
}

- (void)commandButtonPushed:(id)sender {
    UIActionSheet* commandPicker = [[[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Picture", @"Apps", @"Broadcast", nil] autorelease];
    
    [commandPicker showInView:self.view];
}


- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0: // picture
        {
            UIImagePickerController* picker = [[[UIImagePickerController alloc] init] autorelease];
            [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
            [picker setDelegate:self];
            
            [self presentModalViewController:picker animated:YES];
            break;
        }
        case 1:// apps
        {   
            /*NSString* appId = @"edu.stanford.mobisocial.tictactoe";
            
            NSMutableArray* userKeys = [NSMutableArray array];
            for (User* user in [feed members]) {
                if ([[user name] rangeOfString:@"willem" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    [userKeys addObject:[user id]];
                }
                
                if ([userKeys count] >= 2)
                    break;
            }
            
            NSMutableDictionary* appDict = [[[NSMutableDictionary alloc] init] autorelease];
            [appDict setObject:userKeys forKey:@"membership"];
            
            Obj* obj = [[[Obj alloc] initWithType:@"appstate"] autorelease];
            [obj setData:appDict];
            
            App* app = [[[App alloc] init] autorelease];
            [app setId: appId];
            [app setFeed: feed];
            
            SignedMessage* msg = [[Musubi sharedInstance] sendMessage:[Message createWithObj:obj forApp:app]];
            [app setMessage:msg];
            
            [self launchApp: app];*/
        }
        case 2: // broadcast
        {
            GPSNearbyGroups* nearby = [[[GPSNearbyGroups alloc] init] autorelease];
            @try {
                [nearby broadcastGroup:feed during:5 withPassword:@""];
            } @catch (NSException* e) {
                UIAlertView* alert = [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Could not broadcast group" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
                [alert show];
            }
            break;
        }
    }
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    
    App* app = [[[App alloc] init] autorelease];
    [app setId:kMusubiAppId];
    [app setFeed:feed];
    
    PictureUpdate* update = [[[PictureUpdate alloc] initWithImage: image] autorelease];
    [[Musubi sharedInstance] sendMessage: [Message createWithObj:[update obj] forApp:app]];
    
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

- (void)launchApp: (App*) app {
    
    HTMLAppViewController* appViewController = (HTMLAppViewController*) [[self storyboard] instantiateViewControllerWithIdentifier:@"app"];
    [appViewController setApp: app];
    
    [[self navigationController] pushViewController:appViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    /*
    SignedMessage* msg = [self msgForIndexPath:indexPath];
    if (msg != nil) {
        NSString* appId = [msg appId];
        if (appId == nil) {
            appId = kMusubiAppId;
        }
        
        App* app = [[[App alloc] init] autorelease];
        [app setId: appId];
        [app setFeed: feed];
        [app setMessage: msg];
        
        [self launchApp:app];
    }*/
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ([textField text].length > 0) {
        StatusUpdate* update = [[[StatusUpdate alloc] initWithText: [textField text]] autorelease];
        
        App* app = [[[App alloc] init] autorelease];
        [app setId: kMusubiAppId];
        [app setFeed: feed];

        [[Musubi sharedInstance] sendMessage: [Message createWithObj:[update obj] forApp:app]];
        [textField setText:@""];
    }
}

@end
