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
//  PictureOverlayViewController.m
//  musubi
//
//  Created by Willem Bult on 6/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PictureOverlayViewController.h"
#import "PictureEditViewController.h"
#import "Three20/Three20.h"
#import "MusubiStyleSheet.h"

@implementation PictureOverlayViewController

@synthesize imagePickerController = _imagePickerController;
@synthesize delegate = _delegate;

- (id)init
{
    if (self = [super init])
    {
        self.imagePickerController = [[UIImagePickerController alloc] init];
        self.imagePickerController.delegate = self;
        
        self.captionButton.hidden = NO;
        self.captionView.hidden = YES;
        
        UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
        gestureRecognizer.cancelsTouchesInView = NO;
        [self.view addGestureRecognizer:gestureRecognizer];
    }
    
    return self;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)setupImagePicker:(UIImagePickerControllerSourceType)sourceType
{
    self.imagePickerController.sourceType = sourceType;
    
    if (sourceType == UIImagePickerControllerSourceTypeCamera)
    {
        // user wants to use the camera interface
        //
        self.imagePickerController.showsCameraControls = YES;
        
        if ([[self.imagePickerController.cameraOverlayView subviews] count] == 0)
        {
            // setup our custom overlay view for the camera
            //
            // ensure that our custom view's frame fits within the parent frame
            CGRect overlayViewFrame = self.imagePickerController.cameraOverlayView.frame;
            CGRect newFrame = CGRectMake(0.0, 50.0,
                                         CGRectGetWidth(overlayViewFrame),
                                         366);
            self.view.frame = newFrame;
            
            [self.imagePickerController.cameraOverlayView addSubview:self.view];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}
- (void)viewDidUnload {
    [super viewDidUnload];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (IBAction) showCaption:(id)sender {
    self.captionView.hidden = NO;
    [self.captionField becomeFirstResponder];
}

- (TTButton*) captionButton {
    if (!_captionButton) {
        _captionButton = [[TTButton alloc] init];
        _captionButton.frame = CGRectMake(210, 328, 100, 34);
        [_captionButton setStyle:[MusubiStyleSheet transparentRoundedButton:UIControlStateNormal] forState:UIControlStateNormal]; 
        [_captionButton setStyle:[MusubiStyleSheet transparentRoundedButton:UIControlStateHighlighted] forState:UIControlStateHighlighted]; 
        [_captionButton setTitle:@"Caption" forState:UIControlStateNormal];
        [_captionButton addTarget:self action:@selector(showCaption:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:_captionButton];
    }
    return _captionButton;
}

- (UILabel*) captionLabel {
    if (!_captionLabel) {
        _captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 333, 320, 44)];
        _captionLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        _captionLabel.font = [UIFont systemFontOfSize:14];
        _captionLabel.textColor = [UIColor whiteColor];
        _captionLabel.textAlignment = UITextAlignmentCenter;
        
        [self.view addSubview:_captionLabel];
    }
    
    return _captionLabel;
}

- (UIView*) captionView {
    if (!_captionView) {
        _captionView = [[TTView alloc] initWithFrame:CGRectMake(0, 410, 320, 44)];
        ((TTView*)_captionView).style = [MusubiStyleSheet bottomPanelStyle];
        _captionView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        
        [self.view addSubview:_captionView];
    }
    
    return _captionView;
}

- (UITextField*) captionField {
    if (!_captionField) {
        _captionField = [[UITextField alloc] initWithFrame: CGRectMake(10, 5, 300, 34)];
        _captionField.backgroundColor = [UIColor clearColor];
        _captionField.font = [UIFont systemFontOfSize:16.0];
        _captionField.delegate = self;
        _captionField.textColor = [UIColor blackColor];
        
        TTView* statusFieldBox = [[TTView alloc] initWithFrame:CGRectMake(5, 5, _captionField.frame.size.width, _captionField.frame.size.height)];
        statusFieldBox.backgroundColor = [UIColor whiteColor];
        statusFieldBox.style = [MusubiStyleSheet textViewBorder];
        [statusFieldBox addSubview: _captionField];
        
        [self.captionView addSubview:statusFieldBox];
    }
    
    return _captionField;
}

- (void) hideKeyboard {
    [self.captionField resignFirstResponder];
}

- (void) keyboardDidShow: (NSNotification*) notification {
    CGRect keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIWindow *window = [[[UIApplication sharedApplication] windows]objectAtIndex:0];
    CGRect keyboardFrameConverted = CGRectNull;
    keyboardFrameConverted = [self.view convertRect:keyboardFrame fromView:window];
    
    self.captionView.center = CGPointMake(160, keyboardFrameConverted.origin.y - self.captionView.frame.size.height / 2);
}

- (void) keyboardWillHide: (NSNotification*) notification {
    self.captionView.hidden = YES;
    self.captionLabel.text = self.captionField.text;
    
    if (self.captionLabel.text.length) {
        self.captionLabel.hidden = NO;
        self.captionButton.center = CGPointMake(260, 302);
    } else {
        self.captionLabel.hidden = YES;
        self.captionButton.center = CGPointMake(260, 346);
    }
}

#pragma mark - Text view delegate


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}



#pragma mark -
#pragma mark UIImagePickerControllerDelegate

// this get called when an image has been chosen from the library or taken from the camera
//
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    [((UIViewController*)self.delegate) dismissModalViewControllerAnimated:NO];
    
    if (self.imagePickerController.sourceType != UIImagePickerControllerSourceTypeCamera) {
        PictureEditViewController* editVC = [[PictureEditViewController alloc] init];
        editVC.overlayViewController = self;
        editVC.picture = image;
        editVC.delegate = self;
        
        [((UIViewController*)self.delegate) presentModalViewController:editVC animated:YES];
    } else {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        [self.delegate picturePickerFinishedWithPicture:image withCaption:self.captionLabel.text];        
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [((UIViewController*)self.delegate) dismissModalViewControllerAnimated:YES];
}

#pragma mark PictureEditViewControllerDelegate

- (void)pictureEditViewController:(PictureEditViewController *)vc chosePicture:(UIImage *)picture {    
    [((UIViewController*)self.delegate) dismissModalViewControllerAnimated:YES];
    [self.delegate picturePickerFinishedWithPicture:picture withCaption:self.captionLabel.text];
}

- (void)pictureEditViewController:(PictureEditViewController *)vc didCancel:(BOOL)cancel {
    [((UIViewController*)self.delegate) dismissModalViewControllerAnimated:YES];
}

@end
