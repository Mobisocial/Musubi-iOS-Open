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
//  Created by Willem Bult on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedListViewController.h"
#import "Musubi.h"
#import "FeedListDataSource.h"
#import "FeedListModel.h"
#import "FeedListItem.h"
#import "PersistentModelStore.h"
#import "AMQPTransport.h"
#import "AMQPConnectionManager.h"

#import "FeedViewController.h"

#import "AppManager.h"
#import "MApp.h"
#import "FeedManager.h"
#import "MFeed.h"

#import "ObjHelper.h"
#import "IntroductionObj.h"

@implementation FeedListViewController {
    NSDate* nextRedraw;
    NSDate* lastRedraw;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // TTTableViewController doesn't implement initWithCoder: so do the required init here
        _lastInterfaceOrientation = self.interfaceOrientation;
        _tableViewStyle = UITableViewStylePlain;
        _clearsSelectionOnViewWillAppear = YES;
        _flags.isViewInvalid = YES;
        
        [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(feedUpdated:) name:kMusubiNotificationUpdatedFeed object:nil];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    incomingLabel = [[UILabel alloc] init];
    incomingLabel.font = [UIFont systemFontOfSize: 13.0];
    incomingLabel.text = @"";
    incomingLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:.5];
    incomingLabel.textColor = [UIColor colorWithWhite:1 alpha:1];
    
    self.variableHeightRows = YES;    
    
    // We only need to know when a message starts getting decrypted, when it is completely processed
    [[Musubi sharedInstance].transport.connMngr addObserver:self forKeyPath:@"connectionState" options:0 context:nil];
    [[Musubi sharedInstance] addObserver:self forKeyPath:@"transport" options:0 context:nil];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updatePending) name:kMusubiNotificationMessageDecodeStarted object:nil];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updatePending) name:kMusubiNotificationMessageDecodeFinished object:nil];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updatePending) name:kMusubiNotificationUpdatedFeed object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [incomingLabel removeFromSuperview];
    [self.view addSubview:incomingLabel];
    [self updatePending];
    
    // Cardinal
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:164.0/256.0 green:0 blue:29.0/256.0 alpha:1];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)createModel {
    self.dataSource = [[FeedListDataSource alloc] init];
}

- (id<UITableViewDelegate>)createDelegate {
    return [[TTTableViewVarHeightDelegate alloc] initWithController:self];
}

- (void) feedUpdated: (NSNotification*) notification {    
    if (![NSThread currentThread].isMainThread) {
        [self performSelectorOnMainThread:@selector(feedUpdated:) withObject:notification waitUntilDone:NO];
        return;
    }

    if(nextRedraw) {
        return;
    }
    if(lastRedraw) {
        NSDate* now = [NSDate date];
        if([lastRedraw timeIntervalSinceDate:now] > 1) {
        
        } else {
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 11 * NSEC_PER_SEC / 10);
            nextRedraw = [lastRedraw dateByAddingTimeInterval:1];
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self feedUpdated:notification];
            });
        }
    }
    FeedListDataSource* feeds = self.dataSource;
    NSManagedObjectID* oid = notification.object;
    [feeds invalidateObjectId:oid];
    lastRedraw = [NSDate date];
    nextRedraw = nil;
    [self reload];   
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"transport"]) {
        [[Musubi sharedInstance].transport.connMngr addObserver:self forKeyPath:@"connectionState" options:0 context:nil];
    } else {
        [self updatePending];
    }
}


// TODO: This needs to be in some other class, but let's keep it simple for now
- (void)updatePending {
    if(![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(updatePending) withObject:nil waitUntilDone:NO];
        return;
    }
    
    NSString* newText = nil;
    
    AMQPTransport* transport = [Musubi sharedInstance].transport;
    NSString* connectionState = transport ? transport.connMngr.connectionState : @"Starting up...";
    
    if(connectionState) {
        newText = connectionState;
    } else {
        PersistentModelStore* store = [Musubi sharedInstance].mainStore;
        NSArray* encoded = [store query:[NSPredicate predicateWithFormat:@"(processed == NO) AND (outbound == NO)"] onEntity:@"EncodedMessage"];
        
        int pending = encoded.count;
        
        if (pending > 0) {
            newText = [NSString stringWithFormat: @"Decrypting %@incoming message%@...", pending > 1 ? [NSString stringWithFormat:@"%d ", pending] : @"", pending > 1 ? @"s" : @""];
        }
    }
    
    if (newText.length > 0) {
        incomingLabel.hidden = NO;
        [incomingLabel setText: [NSString stringWithFormat:@"  %@", newText]];
        if (incomingLabel.superview == self.view) {
            [incomingLabel setFrame:CGRectMake(0, 386, 320, 30)];
        } else {
            [incomingLabel setFrame:CGRectMake(0, 0, 320, 30)];
        }
    } else {
        incomingLabel.hidden = YES;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"ShowFeed"]) {
        FeedViewController *vc = [segue destinationViewController];
        FeedListItem* item = sender;
        vc.newerThan = item.end;
        vc.startingAt = item.start;
        [vc setFeed: item.feed];
        [vc.view addSubview:incomingLabel];
        [vc setDelegate:self];
        [self updatePending];
    } else if ([[segue identifier] isEqualToString:@"CreateNewFeed"]) {
        FriendPickerViewController *vc = [segue destinationViewController];
        [vc setDelegate:self];
    } 
}

- (void)newConversation:(id)sender
{
    //TODO: UIActionSheet
    
    UIActionSheet* newConversationPicker = [[UIActionSheet alloc] initWithTitle:@"New conversation" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Create from contacts", @"Join nearby group", nil];
    
    [newConversationPicker showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    
    switch (buttonIndex) {
        case 0: // create from contact list
        {
            FriendPickerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"FriendPicker"];
            [vc setDelegate:self];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
        case 1: // find nearby groups
        {   
            break;
        }
    }
}

- (void)didSelectObject:(id)object atIndexPath:(NSIndexPath *)indexPath {
    FeedListItem* item = [[((FeedListDataSource*)self.dataSource).items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"ShowFeed" sender:item];
}

- (void)friendsForNewConversationSelected:(NSArray *)selection {
    [self friendsSelected:selection];
}

- (void) friendsSelected: (NSArray*) selection {
    PersistentModelStore* store = [Musubi sharedInstance].mainStore;
    
    AppManager* am = [[AppManager alloc] initWithStore:store];
    MApp* app = [am ensureSuperApp];
    
    FeedManager* fm = [[FeedManager alloc] initWithStore: store];
    MFeed* f = [fm createExpandingFeedWithParticipants:selection];
    
    Obj* invitationObj = [[IntroductionObj alloc] initWithIdentities:selection];
    [ObjHelper sendObj: invitationObj toFeed:f fromApp:app usingStore: store];
    
    [self.navigationController popViewControllerAnimated:NO];
    [self performSegueWithIdentifier:@"ShowFeed" sender:[[FeedListItem alloc] initWithFeed:f after:nil before:nil]];
}

@end
 
