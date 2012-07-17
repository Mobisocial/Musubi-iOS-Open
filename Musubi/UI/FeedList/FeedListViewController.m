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
#import "NearbyViewController.h"

#import "FeedViewController.h"

#import "AppManager.h"
#import "MApp.h"
#import "FeedManager.h"
#import "MFeed.h"

#import "ObjHelper.h"
#import "IntroductionObj.h"
#import "AccountManager.h"

@implementation FeedListViewController {
    NSDate* nextRedraw;
    NSDate* lastRedraw;
    NSDate* nextPendingRedraw;
    NSDate* lastPendingRedraw;
}

@synthesize initialView = _initialView;

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
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updatePending) name:kMusubiNotificationMessageEncodeStarted object:nil];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updatePending) name:kMusubiNotificationMessageDecodeStarted object:nil];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updatePending) name:kMusubiNotificationMessageDecodeFinished object:nil];
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(updatePending) name:kMusubiNotificationUpdatedFeed object:nil];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [incomingLabel removeFromSuperview];
    [self.view addSubview:incomingLabel];
    [self updatePending];
    
    // Color
    self.navigationController.navigationBar.tintColor = [((id)[TTStyleSheet globalStyleSheet]) navigationBarTintColor];
    
    AccountManager* accMgr = [[AccountManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    
    if ([accMgr claimedAccounts].count == 0) {
        [self performSegueWithIdentifier:@"Welcome" sender:self];
    }    
    
    [self displayNoFeedViewIfNeeded];
}

- (void) displayNoFeedViewIfNeeded {
    if (((FeedListDataSource*)self.dataSource).items.count == 0) {
        if (self.initialView == nil) {
            self.tableView.hidden = YES;
            self.view.backgroundColor = [UIColor clearColor];

            noFeedsView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
            self.initialView = noFeedsView;
            noFeedsView.backgroundColor = [((id)[TTStyleSheet globalStyleSheet]) tablePlainBackgroundColor];
            
            [self.view addSubview:noFeedsView];
            UIImageView* cloud = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cloud.png"]];
            cloud.frame = CGRectMake(50, 30, 220, 150);
            cloud.contentMode = UIViewContentModeScaleAspectFit;
            [noFeedsView addSubview:cloud];
            
            UILabel* headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 200, 220, 30)];
            headerLabel.font = [UIFont boldSystemFontOfSize:16.0];
            headerLabel.textAlignment = UITextAlignmentCenter;
            headerLabel.text = @"No conversations yet :(";
            headerLabel.backgroundColor = [UIColor clearColor];
            [noFeedsView addSubview:headerLabel];
            
            UITextView* infoLabel = [[UITextView alloc] initWithFrame:CGRectMake(50, 250, 220, 60)];
            infoLabel.font = [UIFont systemFontOfSize: 14];
            infoLabel.textAlignment = UITextAlignmentCenter;
            infoLabel.text = @"Let's pick a few friends to start a chat with!";
            infoLabel.backgroundColor = [UIColor clearColor];
            infoLabel.editable = NO;
            infoLabel.userInteractionEnabled = NO;
            [infoLabel sizeToFit];
            [noFeedsView addSubview:infoLabel];
            
            TTButton* startButton = [[TTButton alloc] initWithFrame:CGRectMake(60, 320, 200, 50)];
            [startButton setStyle:[self startButtonStyle:UIControlStateNormal] forState:UIControlStateNormal];
            [startButton setStyle:[self startButtonStyle:UIControlStateHighlighted] forState:UIControlStateHighlighted];
            [startButton setTitle:@"Start a chat" forState:UIControlStateNormal];
            [noFeedsView addSubview:startButton];
            
            [startButton addTarget:self action:@selector(showFriendPicker) forControlEvents:UIControlEventTouchUpInside];
        }
    } else {
        if (self.initialView != nil) {
            [self.initialView removeFromSuperview];
            self.tableView.hidden = NO;
            self.initialView = nil;
        }
    }

}

- (TTStyle*)startButtonStyle:(UIControlState)state {
    UIFont* font = [UIFont boldSystemFontOfSize:14];
    
    if (state == UIControlStateNormal) {
        return
        [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] next:
         [TTInsetStyle styleWithInset:UIEdgeInsetsMake(0, 0, 1, 0) next:
          [TTShadowStyle styleWithColor:RGBACOLOR(255,255,255,0) blur:1 offset:CGSizeMake(0, 1) next:
           [TTLinearGradientFillStyle styleWithColor1:RGBCOLOR(255, 255, 255)
                                               color2:RGBCOLOR(216, 221, 231) next:
            [TTSolidBorderStyle styleWithColor:RGBCOLOR(161, 167, 178) width:1 next:
             [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 9, 12) next:
              [TTTextStyle styleWithFont:font color:TTSTYLEVAR(linkTextColor)
                             shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
                            shadowOffset:CGSizeMake(0, -1) next:nil]]]]]]];
    } else if (state == UIControlStateHighlighted) {
        return
        [TTShapeStyle styleWithShape:[TTRoundedRectangleShape shapeWithRadius:8] next:
         [TTInsetStyle styleWithInset:UIEdgeInsetsMake(0, 0, 1, 0) next:
          [TTShadowStyle styleWithColor:RGBACOLOR(255,255,255,0.9) blur:1 offset:CGSizeMake(0, 1) next:
           [TTLinearGradientFillStyle styleWithColor1:RGBCOLOR(225, 225, 225)
                                               color2:RGBCOLOR(196, 201, 221) next:
            [TTSolidBorderStyle styleWithColor:RGBCOLOR(161, 167, 178) width:1 next:
             [TTBoxStyle styleWithPadding:UIEdgeInsetsMake(10, 12, 9, 12) next:
              [TTTextStyle styleWithFont:font color:[UIColor whiteColor]
                             shadowColor:[UIColor colorWithWhite:255 alpha:0.4]
                            shadowOffset:CGSizeMake(0, -1) next:nil]]]]]]];
    } else {
        return nil;
    }
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
        if([lastRedraw timeIntervalSinceDate:now] < -1) {
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 11 * NSEC_PER_SEC / 10);
            nextRedraw = [lastRedraw dateByAddingTimeInterval:1];
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                nextRedraw = nil;
                lastRedraw = nil;
                [self feedUpdated:notification];
            });
            return;
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
    
    if(nextPendingRedraw) {
        return;
    }
    if(lastPendingRedraw) {
        NSDate* now = [NSDate date];
        if([lastPendingRedraw timeIntervalSinceDate:now] < -.25) {
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 11 * NSEC_PER_SEC / 10);
            nextPendingRedraw = [lastPendingRedraw dateByAddingTimeInterval:.25];
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                nextPendingRedraw = nil;
                lastPendingRedraw = nil;
                [self updatePending];
            });
            return;
        }
    }
    lastPendingRedraw = [NSDate date];
    nextPendingRedraw = nil;

    
    NSString* newText = nil;
    
    AMQPTransport* transport = [Musubi sharedInstance].transport;
    NSString* connectionState = transport ? transport.connMngr.connectionState : @"Starting up...";
    
    if(connectionState) {
        newText = connectionState;
    } else {
        PersistentModelStore* store = [Musubi sharedInstance].mainStore;
        NSArray* encoding = [store query:[NSPredicate predicateWithFormat:@"(encoded == nil) AND (sent == NO)"] onEntity:@"Obj"];
        int pending = encoding.count;
        
        if (pending > 0) {
            newText = [NSString stringWithFormat: @"Encrypting %@outgoing message%@...", pending > 1 ? [NSString stringWithFormat:@"%d ", pending] : @"", pending > 1 ? @"s" : @""];
        } else {
            NSArray* decoding = [store query:[NSPredicate predicateWithFormat:@"(processed == NO) AND (outbound == NO)"] onEntity:@"EncodedMessage"];
            
            pending = decoding.count;
            
            if (pending > 0) {
                newText = [NSString stringWithFormat: @"Decrypting %@incoming message%@...", pending > 1 ? [NSString stringWithFormat:@"%d ", pending] : @"", pending > 1 ? @"s" : @""];
            }
        }
        
        
    }
    
    /*if (newText.length > 0) {
        incomingLabel.hidden = NO;
        [incomingLabel setText: [NSString stringWithFormat:@"  %@", newText]];
        if (incomingLabel.superview == self.view) {
            [incomingLabel setFrame:CGRectMake(0, 386, 320, 30)];
        } else {
            [incomingLabel setFrame:CGRectMake(0, 0, 320, 30)];
        }
    } else {
        incomingLabel.hidden = YES;
    }*/
    incomingLabel.hidden = YES;
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
            [self showFriendPicker];
            break;
        }
        case 1: // find nearby groups
        {   
            NearbyViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"NearbyFeeds"];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
    }
}

- (void) showFriendPicker {
    FriendPickerViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"FriendPicker"];
    [vc setDelegate:self];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didSelectObject:(id)object atIndexPath:(NSIndexPath *)indexPath {
    [super didSelectObject:object atIndexPath:indexPath];
    
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
    [FeedViewController sendObj: invitationObj toFeed:f fromApp:app usingStore: store];
    
    [self.navigationController popViewControllerAnimated:NO];
    [self performSegueWithIdentifier:@"ShowFeed" sender:[[FeedListItem alloc] initWithFeed:f after:nil before:nil]];
}

@end
 
