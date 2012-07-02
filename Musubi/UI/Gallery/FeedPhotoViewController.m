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
//  FeedPhotoViewController.m
//  musubi
//
//  Created by Willem Bult on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedPhotoViewController.h"
#import "FeedPhoto.h"
#import "FeedViewController.h"
#import "AppManager.h"
#import "IdentityManager.h"
#import "MIdentity.h"
#import "HTMLAppViewController.h"
#import "FeedNameObj.h"
#import "ObjHelper.h"
#import "SHK.h"
#import "PersistentModelStore.h"
#import "ProfileObj.h"

@implementation FeedPhotoViewController

@synthesize feedViewController = _feedViewController, actionButton = _actionButton;


#define kMainActionSheetTag 0
#define kSetAsActionSheetTag 1

- (id)initWithFeedViewController:(FeedViewController *)feedVC andPhoto: (FeedPhoto*) photo {
    self = [super initWithPhoto:photo];
    if (self) {
        _feedViewController = feedVC;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    UIBarItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                        UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    NSMutableArray* items = [NSMutableArray arrayWithArray:_toolbar.items];
    [items addObject: space];
    [items addObject: self.actionButton];
    _toolbar.items = items;
}

- (UIBarButtonItem*) actionButton {
    if (!_actionButton) {
        _actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                            target:self
                        action:@selector(openMainActionSheet)];
        
        
        
    }
    
    return _actionButton;
}

- (void)openMainActionSheet 
{
    UIActionSheet* actions = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Save Image", @"Edit Image", @"Share Image", @"Set as...", nil];   
    
    [actions setTag:kMainActionSheetTag];
    [actions showInView:self.view];
}

- (void)openSetAsActionSheet 
{
    UIActionSheet* actions = [[UIActionSheet alloc] initWithTitle:@"Set as..." delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Profile Picture", @"Conversation Photo", nil];   
    
    [actions setTag:kSetAsActionSheetTag];
    [actions showInView:self.view];
}


- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch ([actionSheet tag]) {
        case kMainActionSheetTag: {
            switch(buttonIndex)  {
                case 0:
                {
                    // Save the image to the Camera Roll
                    NSURL    *aUrl  = [NSURL URLWithString:[self.centerPhoto URLForVersion:TTPhotoVersionLarge]];
                    NSData   *data = [NSData dataWithContentsOfURL:aUrl];
                    UIImage  *img  = [[UIImage alloc] initWithData:data];
                    
                    UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil);
                    break;
                }
                case 1:
                {
                    // Open the image in MusuSketch
                    FeedPhoto* feedPhoto = (FeedPhoto*)self.centerPhoto;
                    NSString* appId = @"musubi.sketch";
                    AppManager* appMgr = [[AppManager alloc] initWithStore: [Musubi sharedInstance].mainStore];
                    MApp* app = [appMgr ensureAppWithAppId:appId];
                    MObj* obj = feedPhoto.obj;
                    [FeedViewController launchApp:app withObj:obj feed:obj.feed andController:_feedViewController popViewController:true];
                    
                    break;
                }
                case 2:
                {
                    // Share the image
                    NSURL    *aUrl  = [NSURL URLWithString:[self.centerPhoto URLForVersion:TTPhotoVersionLarge]];
                    NSData   *data = [NSData dataWithContentsOfURL:aUrl];
                    UIImage  *img  = [[UIImage alloc] initWithData:data];
                    SHKItem *item = [SHKItem image:img title:@"Picture from Musubi"];
                    
                    // Get the ShareKit action sheet
                    SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
                    
                    // ShareKit detects top view controller (the one intended to present ShareKit UI) automatically,
                    // but sometimes it may not find one. To be safe, set it explicitly
                    [SHK setRootViewController:self];
                    
                    // Display the action sheet
                    [actionSheet showInView:self.view];
                    break;
                }
                case 3:
                {
                    [self openSetAsActionSheet];
                    break;
                }    
            break;
            }
        }
        case kSetAsActionSheetTag: {
            switch(buttonIndex)  {
                case 0:
                {
                    PersistentModelStore* store = [[Musubi sharedInstance] newStore];
                    IdentityManager* idm = [[IdentityManager alloc] initWithStore:store];
                    NSArray* mine = [idm ownedIdentities];
                    if(mine.count == 0) {
                        NSLog(@"No identity, connect an account");
                        return;
                    }
                    NSURL    *aUrl  = [NSURL URLWithString:[self.centerPhoto URLForVersion:TTPhotoVersionLarge]];
                    NSData   *data = [NSData dataWithContentsOfURL:aUrl];
                    UIImage  *img  = [[UIImage alloc] initWithData:data];
                    
                    UIImage* resized = [img centerFitAndResizeTo:CGSizeMake(256, 256)];
                    NSData* thumbnail = UIImageJPEGRepresentation(resized, 0.90);
                    
                    long long now = (long long)([[NSDate date] timeIntervalSince1970] * 1000);
                    for(MIdentity* me in mine) {
                        me.musubiThumbnail = thumbnail;
                        me.receivedProfileVersion = now;
                    }
                    [store save];
                    [ProfileObj sendAllProfilesWithStore:store];
                    break;
                }
                case 1:
                {
                     MFeed* feed = ((FeedPhoto*)self.centerPhoto).obj.feed;
                     NSURL    *aUrl  = [NSURL URLWithString:[self.centerPhoto URLForVersion:TTPhotoVersionLarge]];
                     NSData   *data = [NSData dataWithContentsOfURL:aUrl];
                     UIImage  *img  = [[UIImage alloc] initWithData:data];
                     
                     UIImage* resized = [img centerFitAndResizeTo:CGSizeMake(256, 256)];
                     NSData* thumbnail = UIImageJPEGRepresentation(resized, 0.90);
                     
                     
                     NSString* name = feed.name;
                     
                     FeedNameObj* name_change = [[FeedNameObj alloc] initWithName:name andThumbnail:thumbnail];
                     
                     AppManager* am = [[AppManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
                     MApp* app = [am ensureSuperApp];
                     
                     [ObjHelper sendObj:name_change toFeed:feed fromApp:app usingStore:[Musubi sharedInstance].mainStore];
                     
                     [_feedViewController refreshFeed];
                     
                     [[self modalViewController] dismissModalViewControllerAnimated:YES];
                    break;
                }
            break;
            }
        }
    }
}
            
@end
