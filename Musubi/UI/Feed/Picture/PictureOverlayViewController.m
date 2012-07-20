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
#import "Three20/Three20.h"
#import "MusubiStyleSheet.h"
#import "Three20UI+Additions.h"

@implementation PictureOverlayViewController

@synthesize imagePickerController = _imagePickerController;
@synthesize delegate = _delegate;
@synthesize toolBar = _toolBar;

- (id)initForImagePicker:(UIImagePickerControllerSourceType)sourceType
{
    if (self = [super init])
    {
        self.imagePickerController = [[UIImagePickerController alloc] init];
        self.imagePickerController.sourceType = sourceType;
        self.imagePickerController.delegate = self;
        
        if (sourceType == UIImagePickerControllerSourceTypeCamera) {
            self.imagePickerController.showsCameraControls = NO;
            [self.imagePickerController.cameraOverlayView addSubview:self.view];
            self.view.frame = CGRectMake(0.0, 0.0, 320, 480);
        } else {            
            self.view.frame = CGRectMake(0.0, 0.0, 320, 460);
        }
        
        _preview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, self.view.height-55)];
        _preview.backgroundColor = [UIColor blackColor];
        _preview.contentMode = UIViewContentModeScaleAspectFit;
        _preview.hidden = YES;
        [self.view addSubview:_preview];
        
        _toolBar=[[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.height-55, 320, 55)];
        _toolBar.barStyle = UIBarStyleBlackOpaque;
        _toolBar.items = self.toolbarItems;
        [self.view addSubview:_toolBar];
        
        //self.editButton.hidden = NO;
        self.captionButton.hidden = YES;
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

- (NSArray*) toolbarItems {
    if (_preview.hidden) {
     return [NSArray arrayWithObjects:
                    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel  target:self action:@selector(cancelPicture:)],
                    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace  target:nil action:nil],
                    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera  target:self action:@selector(shootPicture:)],
                    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace  target:nil action:nil],
                    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace  target:nil action:nil],
                    nil];
    } else {
        UIBarButtonItem* retakeItem = [[UIBarButtonItem alloc] initWithTitle:self.imagePickerController.sourceType == UIImagePickerControllerSourceTypeCamera ?@"Retake" : @"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(retakePicture:)];
        
        UIBarButtonItem* cancelItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPicture:)];
        UIBarButtonItem* editItem = [[UIBarButtonItem alloc] initWithTitle:@"Edit" style:UIBarButtonItemStyleDone target:self action:@selector(editPicture:)];
        UIBarButtonItem* useItem = [[UIBarButtonItem alloc] initWithTitle:@"Use" style:UIBarButtonItemStyleDone target:self action:@selector(usePicture:)];
        
        return [NSArray arrayWithObjects:
                        self.imagePickerController.sourceType == UIImagePickerControllerSourceTypeCamera ? retakeItem : retakeItem,
                        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                        editItem,
                        useItem,
                        nil];
    }
}

- (TTButton*) editButton {
    if (!_editButton) {
        _editButton = [[TTButton alloc] init];
        _editButton.frame = CGRectMake(10, self.view.height-100, 100, 34);
        [_editButton setStyle:[MusubiStyleSheet transparentRoundedButton:UIControlStateNormal] forState:UIControlStateNormal]; 
        [_editButton setStyle:[MusubiStyleSheet transparentRoundedButton:UIControlStateHighlighted] forState:UIControlStateHighlighted]; 
        [_editButton setTitle:@"Edit" forState:UIControlStateNormal];
        [_editButton addTarget:self action:@selector(edit:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:_editButton];
    }
    return _editButton;
}

- (TTButton*) captionButton {
    if (!_captionButton) {
        _captionButton = [[TTButton alloc] init];
        _captionButton.frame = CGRectMake(210, self.view.height-100, 100, 34);
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
        _captionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.view.height-100, 320, 44)];
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
        _captionView = [[TTView alloc] initWithFrame:CGRectMake(0, self.view.height-56, 320, 44)];
        ((TTView*)_captionView).style = [MusubiStyleSheet bottomPanelStyle];
        _captionView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        
        [self.view addSubview:_captionView];
    }
    
    return _captionView;
}

- (UITextField*) captionField {
    if (!_captionField) {
        _captionField = [[UITextField alloc] initWithFrame: CGRectMake(10, 5, 290, 34)];
        _captionField.backgroundColor = [UIColor clearColor];
        _captionField.font = [UIFont systemFontOfSize:16.0];
        _captionField.delegate = self;
        _captionField.textColor = [UIColor blackColor];
        
        TTView* statusFieldBox = [[TTView alloc] initWithFrame:CGRectMake(5, 5, _captionField.frame.size.width+20, _captionField.frame.size.height)];
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
        self.captionButton.center = CGPointMake(260, self.view.height-126);
    } else {
        self.captionLabel.hidden = YES;
        self.captionButton.center = CGPointMake(260, self.view.height-82);
    }
}

#pragma mark - Text view delegate


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}



#pragma mark -
#pragma mark UIImagePickerControllerDelegate


- (IBAction)shootPicture:(id)sender {
    [self.imagePickerController takePicture];
}

- (IBAction)retakePicture:(id)sender {
    _preview.hidden = YES;
    _toolBar.items = self.toolbarItems;
    _captionButton.hidden = YES;
    
    if (self.imagePickerController.sourceType != UIImagePickerControllerSourceTypeCamera) {
        [((UIViewController*)self.delegate) dismissModalViewControllerAnimated:NO];
        [((UIViewController*)self.delegate) presentModalViewController:self.imagePickerController animated:NO];
    }
}

- (IBAction)cancelPicture:(id)sender {
    [((UIViewController*)self.delegate) dismissModalViewControllerAnimated:NO];    
}

- (IBAction)usePicture:(id)sender {
    if (self.imagePickerController.sourceType == UIImagePickerControllerSourceTypeCamera) {
        UIImageWriteToSavedPhotosAlbum(_preview.image, nil, nil, nil);
    }    
    
    [self.delegate picturePickerFinishedWithPicture:_preview.image withCaption:self.captionLabel.text];
    [((UIViewController*)self.delegate) dismissModalViewControllerAnimated:NO];    
}

- (IBAction)editPicture:(id)sender {
    
    AFPhotoEditorController *editorController = [[AFPhotoEditorController alloc] initWithImage: _preview.image];
    [editorController setDelegate:self];
    
    [((UIViewController*)self.delegate) dismissModalViewControllerAnimated:NO];
    [((UIViewController*)self.delegate) presentModalViewController:editorController animated:NO];
}

- (void)photoEditor:(AFPhotoEditorController *)editor finishedWithImage:(UIImage *)image {    
    _preview.image = image;
    
    [((UIViewController*)self.delegate) dismissModalViewControllerAnimated:NO];    
    [((UIViewController*)self.delegate) presentModalViewController:self.imagePickerController animated:NO];
}

- (void)photoEditorCanceled:(AFPhotoEditorController *)editor {
    [((UIViewController*)self.delegate) dismissModalViewControllerAnimated:NO];    
    [((UIViewController*)self.delegate) presentModalViewController:self.imagePickerController animated:NO];
}

// this get called when an image has been chosen from the library or taken from the camera
//
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    
    _preview.image = image;
    _preview.hidden = NO;
    _captionButton.hidden = NO;
    _toolBar.items = self.toolbarItems;
        
    if (self.imagePickerController.sourceType != UIImagePickerControllerSourceTypeCamera) {
        [((UIViewController*)self.delegate) dismissModalViewControllerAnimated:NO];
        [((UIViewController*)self.delegate) presentModalViewController:self animated:NO];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [((UIViewController*)self.delegate) dismissModalViewControllerAnimated:YES];
}

@end
