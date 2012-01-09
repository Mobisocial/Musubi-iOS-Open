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
#import "GPSNearbyGroups.h"

@interface FeedViewController : UITableViewController<MusubiFeedListener, UITextFieldDelegate, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIWebViewDelegate, UIActionSheetDelegate> {
    Feed* feed;
    
    NSMutableDictionary* cellHeights;
    
    NSMutableDictionary* updates;
    ObjRenderer* renderer;
    
    IBOutlet UITextField* updateField;
    NSMutableArray* messages;
}

@property (nonatomic,retain) Feed* feed;

- (SignedMessage* ) msgForIndexPath: (NSIndexPath *)indexPath;
- (IBAction) commandButtonPushed: (id)sender;
- (id<Update>) updateForMessage: (Message*) msg;
- (void)launchApp: (App*) app;

@end
