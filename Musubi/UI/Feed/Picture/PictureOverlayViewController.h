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
//  PictureOverlayViewController.h
//  musubi
//
//  Created by Willem Bult on 6/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AFPhotoEditorController.h"

@class TTButton;

@protocol PictureOverlayViewControllerDelegate
- (void) picturePickerFinishedWithPicture:(UIImage *)picture withCaption: (NSString*) caption;
@end

@interface PictureOverlayViewController : UIViewController<UINavigationControllerDelegate,UIImagePickerControllerDelegate,UITextFieldDelegate,AFPhotoEditorControllerDelegate, UIPopoverControllerDelegate> {
    UIView* _captionView;
    UITextField* _captionField;
    UILabel* _captionLabel;
    TTButton* _captionButton;
    TTButton* _editButton;
    UIToolbar *_toolBar;
    
    UIImageView* _preview;
    int    _screenHeight;
    UIPopoverController* _popover;
}

@property (nonatomic, readonly) UIView* captionView;
@property (nonatomic, readonly) UITextField* captionField;
@property (nonatomic, readonly) UILabel* captionLabel;
@property (nonatomic, readonly) TTButton* captionButton;
@property (nonatomic, readonly) TTButton* editButton;
@property (nonatomic, readonly) UIToolbar* toolBar;
@property (nonatomic, readonly) UIImageView* preview;

@property (nonatomic, strong) UIImagePickerController* imagePickerController;
@property (nonatomic, strong) id<PictureOverlayViewControllerDelegate> delegate;

- (id)initForImagePicker:(UIImagePickerControllerSourceType)sourceType;

@end
