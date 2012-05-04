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
//  FeedViewController.m
//  musubi
//
//  Created by Willem Bult on 10/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "FeedViewController.h"
#import "FeedItemTableCell.h"
#import "FeedManager.h"
#import "ObjManager.h"
#import "MFeed.h"
#import "MObj.h"
#import "MIdentity.h"
#import "MApp.h"
#import "AppManager.h"
#import "FeedManager.h"
#import "Musubi.h"
#import "Obj.h"
#import "ObjRenderer.h"
#import "ObjFactory.h"
#import "ObjHelper.h"
#import "StatusObj.h"
#import "StatusObjItem.h"
#import "StatusObjItemCell.h"
#import "PictureObj.h"
#import "FeedDataSource.h"
#import "NSDate+TimeAgo.h"
#import "PersistentModelStore.h"

@implementation FeedViewController

@synthesize feed, feedManager, objManager, objViews, cellHeights, objRenderer, objs;

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)loadView {
    [super loadView];

    CGRect bounds = CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y + 50, self.view.bounds.size.width, self.view.bounds.size.height - 50);
    self.tableView.frame = bounds;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.variableHeightRows = YES;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setFeedManager: [[FeedManager alloc] initWithStore: [Musubi sharedInstance].mainStore]];
    [self setObjManager: [[ObjManager alloc] initWithStore: [Musubi sharedInstance].mainStore]];
    [self setObjRenderer: [[ObjRenderer alloc] init]];
    
    [self setTitle: [feedManager identityStringForFeed: feed]];
    [self refresh];
    
    [self resetUnreadCount];
    [updateField setDelegate:self];
}

- (void)createModel {
    FeedDataSource *feedDataSource = [[FeedDataSource alloc] initWithFeed:feed];
    self.dataSource = feedDataSource;
}

- (id<UITableViewDelegate>)createDelegate {
    return [[TTTableViewVarHeightDelegate alloc]
             initWithController:self];
}

- (void)feedUpdated: (NSNotification*) notification {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(feedUpdated:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    if ([notification.object isEqual:feed.objectID]) {
        [self invalidateFeed];
    }
}

- (void) resetUnreadCount {
    if (feed.numUnread > 0) {
        [feed setNumUnread:0];
        [[Musubi sharedInstance].mainStore save];
    }
}

- (void) invalidateFeed {
    // if we reload right away, the context is not synced up yet or something, because the query results appear out of order
    [self performSelector:@selector(reloadFeed) withObject:nil afterDelay:0];
}

- (void) reloadFeed {
    // This is likely not the way to do it, but it works and can't figure out the correct flow
    [self reload];
    [self refresh];
    
    [self resetUnreadCount];
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
    
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(feedUpdated:) name:kMusubiNotificationUpdatedFeed object:nil];
    // Cardinal
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:164.0/256.0 green:0 blue:29.0/256.0 alpha:1];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"Removing feed view observer");
    [[Musubi sharedInstance].notificationCenter removeObserver:self name:kMusubiNotificationUpdatedFeed object:nil];
    
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

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSString *output = [webView stringByEvaluatingJavaScriptFromString:@"document.body.scrollHeight"];
    NSNumber* height = [NSNumber numberWithInt:[output intValue]];
    [cellHeights setObject:height forKey:[NSNumber numberWithInteger:[webView tag]]];
    
    CGRect frame = [webView frame];
    [webView setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, [height floatValue])];
    
    [self.tableView beginUpdates];
    [self.tableView setNeedsLayout];
    [self.tableView endUpdates];
}

/*
- (void)newMessage:(SignedMessage *)message {
    if (message != nil) {
        [self displayMessage:message];
        [[self tableView] performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:FALSE];
    }
}
*/
- (IBAction)commandButtonPushed: (id) sender {
    UIActionSheet* commandPicker = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Picture", @"Picture From Album", nil];
    
    [commandPicker showFromTabBar: self.tabBarController.tabBar];
}


- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0: // picture
        {
            UIImagePickerController* picker = [[UIImagePickerController alloc] init];
            [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
            [picker setDelegate:self];
            
            
            [self presentModalViewController:picker animated:YES];
            break;
        }
        case 1:// apps
        {   
            UIImagePickerController* picker = [[UIImagePickerController alloc] init];
            [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
            [picker setDelegate:self];            
            
            [self presentModalViewController:picker animated:YES];
            break;

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
    }
}


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    
    PictureObj* pic = [[PictureObj alloc] initWithImage: image];
    
    AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    MApp* app = [am ensureAppWithAppId:@"mobisocial.musubi"];
    
    [ObjHelper sendObj:pic toFeed:feed fromApp:app usingStore:[Musubi sharedInstance].mainStore];
    
    [[self modalViewController] dismissModalViewControllerAnimated:YES];
    [self invalidateFeed];    
}

#pragma mark - Table view delegate
/*
- (void)launchApp: (App*) app {
    
    HTMLAppViewController* appViewController = (HTMLAppViewController*) [[self storyboard] instantiateViewControllerWithIdentifier:@"app"];
    [appViewController setApp: app];
    
    [[self navigationController] pushViewController:appViewController animated:YES];
}*/

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
        StatusObj* status = [[StatusObj alloc] initWithText: [textField text]];
        
        AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
        MApp* app = [am ensureAppWithAppId:@"mobisocial.musubi"];
        
        [ObjHelper sendObj:status toFeed:feed fromApp:app usingStore:[Musubi sharedInstance].mainStore];
        
        [textField setText:@""];
        [self invalidateFeed];
    }
}

@end
