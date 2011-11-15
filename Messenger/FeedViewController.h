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
#import "StatusUpdate.h"
#import "PictureUpdate.h"
#import "ObjRenderer.h"

@interface FeedViewController : UITableViewController<MusubiFeedListener, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate> {
    Group* group;
    
    NSMutableDictionary* updates;
    ObjRenderer* renderer;
    
    UITextField* updateField;
    UIButton* pictureButton;
    NSMutableArray* messages;
}

@property (nonatomic,retain) NSMutableDictionary* updates;
@property (nonatomic,retain) Group* group;
@property (nonatomic,retain) NSMutableArray* messages;
@property (nonatomic, retain) IBOutlet UITextField* updateField;
@property (nonatomic, retain) IBOutlet UIButton* pictureButton;

- (Message* ) msgForIndexPath: (NSIndexPath *)indexPath;
- (IBAction) pictureButtonPushed :(id)sender;
- (id<Update>) updateForMessage: (Message*) msg;

@end
