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
#import "HTMLAppViewController.h"
#import "FeedNameObj.h"
#import "ObjHelper.h"

@implementation FeedPhotoViewController

@synthesize feedViewController = _feedViewController;

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
                                                                      action:@selector(openActionSheet)];
        
        
        
    }
    
    return _actionButton;
}


- (void)openActionSheet: (NSInteger)actionSheetId
{
    UIActionSheet* actions = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Save Image", @"Edit Image", @"Share Image", @"Set as conversation photo", nil];
    [actions showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
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
            
            break;
        }
        case 3:
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
        case 4:
        {
            break;
        }            
    }
}
@end
