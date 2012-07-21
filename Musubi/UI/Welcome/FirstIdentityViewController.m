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
//  FirstIdentityViewController.m
//  musubi
//
//  Created by Willem Bult on 7/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FirstIdentityViewController.h"
#import "Three20/Three20.h"
#import "MusubiStyleSheet.h"
#import "MIdentity.h"
#import "IdentityManager.h"
#import "Musubi.h"

@implementation FirstIdentityViewController

@synthesize delegate = _delegate;

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor = [((id)[TTStyleSheet globalStyleSheet]) tablePlainBackgroundColor];
    
    _scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    _scroll.contentSize = CGSizeMake(320, 920);
    _scroll.scrollEnabled = NO;
    [self.view addSubview:_scroll];
  
    TTView* buttonContainer = [[TTView alloc] initWithFrame:CGRectMake(90, 30, 140, 140)];
    buttonContainer.backgroundColor = [UIColor clearColor];
    buttonContainer.style = [MusubiStyleSheet textViewBorder];
    UILabel* imageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 60, 120, 20)];
    imageLabel.font = [UIFont systemFontOfSize:12];
    imageLabel.textAlignment = UITextAlignmentCenter;
    imageLabel.text = @"Choose your picture";
    [buttonContainer addSubview:imageLabel];
    _thumbnailButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _thumbnailButton.frame = CGRectMake(10, 10, 120, 120);
    [_thumbnailButton addTarget:self action:@selector(choosePicture:) forControlEvents:UIControlEventTouchUpInside];
    [buttonContainer addSubview:_thumbnailButton];
    [_scroll addSubview:buttonContainer];
    
    _nameField = [[UITextField alloc] initWithFrame:CGRectMake(50, 200, 220, 29)];
    _nameField.borderStyle = UITextBorderStyleRoundedRect;
    _nameField.delegate = self;
    _nameField.placeholder = @"Your name";
    _nameField.textAlignment = UITextAlignmentCenter;
    [_scroll addSubview:_nameField];
    
    TTButton* startButton = [[TTButton alloc] initWithFrame:CGRectMake(60, 320, 200, 50)];
    [startButton setStyle:[MusubiStyleSheet roundedButtonStyle:UIControlStateNormal] forState:UIControlStateNormal];
    [startButton setStyle:[MusubiStyleSheet roundedButtonStyle:UIControlStateHighlighted] forState:UIControlStateHighlighted];
    [startButton setTitle:@"Start a chat" forState:UIControlStateNormal];
    [startButton addTarget:self action:@selector(startChat:) forControlEvents:UIControlEventTouchUpInside];
    [_scroll addSubview:startButton];
}

- (IBAction)startChat:(id)sender {
    if (_nameField.text.length < 2) {
        [[[UIAlertView alloc] initWithTitle:@"Oops" message:@"Please enter your name so your friends can see who you are." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil] show];
        return;
    }
    
    IdentityManager* idMgr = [[IdentityManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    
    for (MIdentity* ident in idMgr.ownedIdentities) {
        ident.musubiName = _nameField.text;
        ident.musubiThumbnail = UIImageJPEGRepresentation([_thumbnailButton imageForState:UIControlStateNormal], 0.9);
        [idMgr updateIdentity:ident];
    }
    
    [_delegate identityCreated];
}

- (IBAction)choosePicture:(id)sender {    
    UIActionSheet* commandPicker = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Picture", @"Picture From Album", nil];
    
    [commandPicker showInView:self.view];
}


- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
        case 0: // take picture
        {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                UIImagePickerController* picker = [[UIImagePickerController alloc] init];
                picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                picker.delegate = self;
                [self presentModalViewController:picker animated:YES];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"This device doesn't have a camera" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            }
            break;
        }
        case 1: // existing picture
        {   
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
                UIImagePickerController* picker = [[UIImagePickerController alloc] init];
                picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                picker.delegate = self;
                [self presentModalViewController:picker animated:YES];
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Sorry" message:@"This device doesn't support the photo library" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
            }
            break;
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    [self dismissModalViewControllerAnimated:YES];
    [_thumbnailButton setImage:image forState:UIControlStateNormal];
}


- (UINavigationItem *)navigationItem {
    UINavigationItem* item = [super navigationItem];
    item.hidesBackButton = YES;
    item.title = @"Tell us about yourself";
    return item;
}

- (void)viewWillAppear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void) keyboardWillShow:(NSNotification*)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    // Get the duration of the relevant animation (Not sure why this is here, but it is in the Apple Tutorial
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
        
    _scroll.contentOffset = CGPointMake(0, 40);
    [UIView commitAnimations];
}

- (void) keyboardWillHide:(NSNotification*)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    // Get the duration of the relevant animation (Not sure why this is here, but it is in the Apple Tutorial
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    _scroll.contentOffset = CGPointMake(0, 0); 
    [UIView commitAnimations]; 
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [_nameField resignFirstResponder];
    return YES;
}



@end
