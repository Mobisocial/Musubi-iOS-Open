//
//  PictureUpdate.m
//  musubi
//
//  Created by Willem Bult on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PictureUpdate.h"

@implementation PictureUpdate

@synthesize image;

- (id)initWithData:(NSData*) data {
    return [self initWithImage: [UIImage imageWithData:data]];
}

- (id)initWithImage:(UIImage *)img {
    self = [super init];
    if (self != nil) {
        double scale = MIN(1, 200 / MAX([img size].width, [img size].height));
        if (scale < 1) {
            CGSize newSize = CGSizeMake([img size].width * scale, [img size].height * scale);
            img = [img resizedImage:newSize interpolationQuality:0.9];
        }

        [self setImage:img];
    }
    return self;
}

- (Obj *)obj {    
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:1];
    [dict setObject:UIImageJPEGRepresentation(image, 0.9) forKey:@"data"];

    Obj* obj = [[[Obj alloc] initWithType:kObjTypePicture] autorelease];
    [obj setData: dict];
    return obj;
}

+ (id)createFromObj:(Obj *)obj {
    NSData* data = [[obj data] objectForKey:@"data"];
    return [[[PictureUpdate alloc] initWithData:data] autorelease];
}

@end
