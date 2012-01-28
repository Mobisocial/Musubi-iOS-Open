//
//  NamePictureCell.h
//  Musubi
//
//  Created by Willem Bult on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NamePictureCell : UITableViewCell {
    IBOutlet UITextField* nameTextField;
    IBOutlet UIButton* picture;
}

@property (nonatomic,retain) IBOutlet UIButton* picture;
@property (nonatomic,retain) IBOutlet UITextField* nameTextField;

@end
