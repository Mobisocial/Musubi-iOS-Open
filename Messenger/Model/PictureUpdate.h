//
//  PictureUpdate.h
//  musubi
//
//  Created by Willem Bult on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Update.h"
#import "Obj.h"
#import "NSData+Base64.h"
#import "UIImage+Resize.h"

static NSString* kObjTypePicture = @"picture";

@interface PictureUpdate : NSObject<Update> {
    UIImage* image;
}

@property (nonatomic,retain) UIImage* image;

- (id) initWithData: (NSData *) data;
- (id) initWithImage: (UIImage *) img;
- (Obj*) obj;

+ (id) createFromObj: (Obj*) obj;

@end