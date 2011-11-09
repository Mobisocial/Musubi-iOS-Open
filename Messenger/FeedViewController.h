//
//  FeedViewController.h
//  musubi
//
//  Created by Willem Bult on 10/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Group.h"
#import "Musubi.h"
#import "StatusObj.h"
#import "PictureObj.h"

@interface FeedViewController : UITableViewController<MusubiFeedListener, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    Group* group;
    
    UITextField* updateField;
    UIButton* pictureButton;
    NSMutableArray* messages;
}

@property (nonatomic,retain) Group* group;
@property (nonatomic,retain) NSMutableArray* messages;
@property (nonatomic, retain) IBOutlet UITextField* updateField;
@property (nonatomic, retain) IBOutlet UIButton* pictureButton;

- (SignedObj*) objForIndexPath: (NSIndexPath*) indexPath;
- (Message* ) msgForIndexPath: (NSIndexPath *)indexPath;
- (IBAction) pictureButtonPushed :(id)sender;

@end
