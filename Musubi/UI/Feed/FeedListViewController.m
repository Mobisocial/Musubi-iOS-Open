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
//  FeedListViewController.m
//  musubi
//
//  Created by Willem Bult on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedListViewController.h"
#import "FeedManager.h"
#import "Musubi.h"
#import "MFeed.h"
#import "MIdentity.h"
#import "FeedViewController.h"
#import "FeedListDataSource.h"
#import "PersistentModelStore.h"
#import "MessageDecodeService.h"
#import "ObjPipelineService.h"
#import "MObj.h"

@implementation FeedListViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    incomingLabel = [[UILabel alloc] init];
    incomingLabel.font = [UIFont systemFontOfSize: 13.0];
    incomingLabel.text = @"";
    incomingLabel.backgroundColor = [UIColor orangeColor];
    incomingLabel.textColor = [UIColor whiteColor];

    [self.view addSubview:incomingLabel];
    
    /*CGRect tableFrame = self.tableView.frame;
    [self.tableView setFrame:CGRectMake(tableFrame.origin.x, tableFrame.origin.y, tableFrame.size.width, tableFrame.size.height-40)];*/
    
    
    
    [self setVariableHeightRows:YES];
}


- (void)createModel {
    self.dataSource = [[FeedListDataSource alloc] init];
}

- (id<UITableViewDelegate>)createDelegate {
    
    return [[TTTableViewPlainVarHeightDelegate alloc]
            initWithController:self];
}

- (void)viewDidLayoutSubviews {
    NSLog(@"View: %@", self.view);
    NSLog(@"Table: %@", self.tableView);
    NSLog(@"Label: %@", incomingLabel);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    [self refresh];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
//    self.feedManager = [[FeedManager alloc] initWithStore: [Musubi sharedInstance].mainStore];
//    self.feeds = [feedManager displayFeeds];
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

    // We only need to know when a message starts getting decrypted, when it is completely processed, and we need to check periodically because a decryption may have been cancelled for numerous reasons
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updatePending:) name:kMusubiNotificationAppOpened object:nil];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updatePending:) name:kMusubiNotificationTransportListenerWaitingForMessages object:nil];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updatePending:) name:kMusubiNotificationDecryptingMessage object:nil];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updatePending:) name:kMusubiNotificationUpdatedFeed object:nil];
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:1 target:self selector:@selector(updatePendingFromTimer) userInfo:nil repeats:YES] forMode:NSDefaultRunLoopMode];

    // Cardinal
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:164.0/256.0 green:0 blue:29.0/256.0 alpha:1];
}

- (void)updatePendingFromTimer {
    [self updatePending:nil];
}

- (void)updatePending: (NSNotification*) notification {
    if (![NSThread currentThread].isMainThread) {
        [self performSelectorOnMainThread:@selector(updatePending:) withObject:notification waitUntilDone:NO];
        return;
    }
    
    PersistentModelStore* store = [Musubi sharedInstance].mainStore;
    NSArray* encoded = [store query:[NSPredicate predicateWithFormat:@"(processed == NO) AND (outbound == NO)"] onEntity:@"EncodedMessage"];
    NSArray* objs = [store query:[NSPredicate predicateWithFormat:@"(processed == NO) AND (encoded != nil)"] onEntity:@"Obj"];
    
    
    int pending = encoded.count;
    for (MObj* obj in objs) {
        if (!obj.identity.owned)
            pending += 1;
    }
    
    if (pending > 0) {
        incomingLabel.text = [NSString stringWithFormat: @"  Decrypting %@incoming message%@...", pending > 1 ? [NSString stringWithFormat:@"%d ", pending] : @"", pending > 1 ? @"s" : @""];
        [incomingLabel setFrame:CGRectMake(0, 386, 320, 30)];
        [self.tableView setFrame:CGRectMake(0, 0, 320, 386)];
    } else {
        if ([notification.name isEqualToString:kMusubiNotificationAppOpened]) {
            incomingLabel.text = @"  Checking for incoming messages...";
            [incomingLabel setFrame:CGRectMake(0, 386, 320, 30)];
            [self.tableView setFrame:CGRectMake(0, 0, 320, 386)];            
        } else {
            incomingLabel.text = @"  Waiting for messages";
            [incomingLabel setFrame:CGRectMake(10, 420, 0, 0)];
            [self.tableView setFrame:CGRectMake(0, 0, 320, 416)];            
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    NSLog(@"Removing feed list view observer");    
 //   [[Musubi sharedInstance].notificationCenter removeObserver:self name:kMusubiNotificationUpdatedFeed object:nil];
    
    [super viewWillDisappear:animated];
}

- (void) feedUpdated: (NSNotification*) notification {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(feedUpdated:) withObject:notification waitUntilDone:NO];
        return;
    }

    [self performSelector:@selector(reloadFeeds) withObject:nil afterDelay:0];
//    [self reloadFeeds];
}

- (void) reloadFeeds{
//    [self invalidateModel];
    [self.dataSource load:TTURLRequestCachePolicyDefault more:NO];
//    [self invalidateView];
    [self refresh];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"ShowFeedCustom"]) {
        FeedViewController *vc = [segue destinationViewController];
        [vc setFeed: (MFeed*) sender];
    }
}

- (void)didSelectObject:(id)object atIndexPath:(NSIndexPath *)indexPath {
    MFeed* feed = [((FeedListDataSource*)self.dataSource) feedForIndex:indexPath.row];
    [self performSegueWithIdentifier:@"ShowFeedCustom" sender:feed];
}
 
#pragma mark - Table view data source
/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [feeds count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    MFeed* feed = (MFeed*)[feeds objectAtIndex:indexPath.row];
    [cell.textLabel setText:[feedManager identityStringForFeed:feed]];
    if (feed.numUnread > 0) {
        [cell.detailTextLabel setText:[NSString stringWithFormat:@"%d unread messages", feed.numUnread]];
    } else {
        [cell.detailTextLabel setText:@""];
    }
    
    // Configure the cell...
    
    return cell;
}
*/

@end
