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
//  FeedViewController.h
//  musubi
//
//  Created by Willem Bult on 5/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Three20/Three20.h"
#import "ProfileViewController.h"
#import "AudioRecorderViewController.h"
#import "FeedSettingsViewController.h"
#import "PictureOverlayViewController.h"
#import "FeedItemCell.h"

@class MApp, MFeed, StatusTextView, PictureOverlayViewController;

@protocol FeedViewControllerDelegate
    - (void) friendsForNewConversationSelected:(NSArray*)selection;
@end

@interface FeedViewController : TTTableViewController<UITextViewDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, ProfileViewControllerDelegate, AudioRecorderDelegate, FeedSettingsViewControllerDelegate, PictureOverlayViewControllerDelegate> {
    MFeed* _feed;
    
    PictureOverlayViewController* _pictureViewController;
    
    IBOutlet UIView* mainView;
    IBOutlet TTView* postView;
    IBOutlet UIButton* actionButton;
    IBOutlet TTButton* sendButton;
    IBOutlet StatusTextView* statusField;
    
    
    int lastRow;
}

- (IBAction)sendMessage:(id)sender;
- (void)userChoseAudioData:(NSURL *)file; // AudioRecorderDelegate

@property (nonatomic, retain) MFeed* feed;
@property (nonatomic, weak) id<FeedViewControllerDelegate> delegate;
@property (nonatomic, strong) NSDate* newerThan;
@property (nonatomic, strong) NSDate* startingAt;
@property (nonatomic, strong) AudioRecorderViewController*audioRVC;

@end

// FeedViewTableDelegate

@interface FeedViewTableDelegate : TTTableViewVarHeightDelegate {
    //TTPhotoViewController* gallery;
}

- (void) likedAtIndexPath: (NSIndexPath*) indexPath;
- (void) profilePictureButtonPressedAtIndexPath: (NSIndexPath*) indexPath;

@property (nonatomic, strong) TTPhotoViewController* gallery;
@property (nonatomic, strong) FeedViewController* feedViewController;

@end