//
//  PictureObj.h
//  musubi
//
//  Created by Willem Bult on 4/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#include <UIKit/UIKit.h>

#import "Obj.h"

#define kObjTypePicture @"picture"
#define kMimeField @"mimeType"
#define kTextField @"text"

@interface PictureObj : Obj<RenderableObj> {
    UIImage* _image;
    NSString* _text;
}

@property (nonatomic) UIImage* image;
@property (nonatomic) NSString* text;

- (id) initWithImage: (UIImage*) img;
- (id) initWithImage: (UIImage*) img andText: (NSString*) text;
- (id) initWithRaw: (NSData*)raw;
- (id) initWithRaw:(NSData *)raw andData: (NSDictionary*) data;

@end
