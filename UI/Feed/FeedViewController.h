//
//  FeedViewController.h
//  musubi
//
//  Created by Willem Bult on 10/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Feed.h"
#import "App.h"
#import "Musubi.h"
#import "StatusUpdate.h"
#import "PictureUpdate.h"
#import "AppStateUpdate.h"
#import "ObjRenderer.h"

@interface FeedViewController : UITableViewController<MusubiFeedListener, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIWebViewDelegate> {
    Feed* feed;
    
    NSMutableDictionary* cellHeights;
    
    NSMutableDictionary* updates;
    ObjRenderer* renderer;
    
    UITextField* updateField;
    UIButton* pictureButton;
    NSMutableArray* messages;
}

@property (nonatomic,retain) NSMutableDictionary* updates;
@property (nonatomic,retain) Feed* feed;
@property (nonatomic,retain) NSMutableArray* messages;
@property (nonatomic, retain) IBOutlet UITextField* updateField;
@property (nonatomic, retain) IBOutlet UIButton* pictureButton;

- (SignedMessage* ) msgForIndexPath: (NSIndexPath *)indexPath;
- (IBAction) pictureButtonPushed :(id)sender;
- (IBAction) appButtonPushed :(id)sender;
- (id<Update>) updateForMessage: (Message*) msg;
- (void)launchApp: (App*) app;

@end
