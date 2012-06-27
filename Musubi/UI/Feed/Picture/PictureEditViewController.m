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
//  SharePictureViewController.m
//  musubi
//
//  Created by Willem Bult on 6/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PictureEditViewController.h"
#import "PictureObj.h"
#import "Three20/Three20.h"
#import "MusubiStyleSheet.h"

@implementation PictureEditViewController

@synthesize picture = _picture, delegate = _delegate;
@synthesize pictureView = _pictureView;
@synthesize overlayViewController = _overlayViewController;

- (void)loadView {
    [super loadView];    
    
    _pictureView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 416)];
    [self.view addSubview:_pictureView];
    
    UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 416, 320, 44)];
    toolbar.tintColor = [UIColor colorWithWhite:240.0/255.0 alpha:1.0];
    [self.view addSubview:toolbar];
    
    UIBarButtonItem* retakeButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(rechoosePhoto:)];
    retakeButton.tintColor = [UIColor lightGrayColor];
    
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem* useButton = [[UIBarButtonItem alloc] initWithTitle:@"Use" style:UIBarButtonItemStyleBordered target:self action:@selector(usePhoto:)];
    useButton.tintColor = [UIColor blueColor];
    [toolbar setItems:[NSArray arrayWithObjects:retakeButton, flex, useButton, nil]];
}

- (IBAction)usePhoto:(id)sender {
    if (self.delegate) {
        [self.delegate pictureEditViewController:self chosePicture:_picture];
    }
}

- (IBAction)rechoosePhoto:(id)sender {
    if (self.delegate) {
        [self.delegate pictureEditViewController:self didCancel:YES];
    }
}

- (void)setPicture:(UIImage *)picture {
    _picture = picture;
    self.pictureView.image = picture;
    self.pictureView.contentMode = UIViewContentModeScaleAspectFit;
}

- (void)setOverlayViewController:(UIViewController *)overlayViewController {
    if (_overlayViewController != nil) {
        [_overlayViewController.view removeFromSuperview];
    }
    
    _overlayViewController = overlayViewController;
    _overlayViewController.view.frame = CGRectMake(0, 40, 320, 356);
    [self.view addSubview:_overlayViewController.view];
    [self.view bringSubviewToFront:_overlayViewController.view];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (UIImageView *)pictureView {
    if (_pictureView == nil) {
        _pictureView = [[UIImageView alloc] initWithFrame: CGRectMake(0.0, 0.0, 320.0, 420.0)];
        _pictureView.backgroundColor = [UIColor blackColor];
        _pictureView.contentMode = UIViewContentModeScaleAspectFit;

        [self.view addSubview:_pictureView];
    }
    
    return _pictureView;
}
@end
