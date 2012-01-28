//
//  SettingsViewController.h
//  musubi
//
//  Created by Willem Bult on 1/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NamePictureCell.h"
#import "Identity.h"
#import "UIImage+Resize.h"


@interface SettingsViewController : UITableViewController<UITextFieldDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>

- (IBAction) pictureClicked: (id)sender;

@end
