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
//  PictureObj.m
//  musubi
//
//  Created by Willem Bult on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PictureObj.h"

@implementation PictureObj

@synthesize image;

- (id)initWithData:(NSData*) data {
    return [self initWithImage: [UIImage imageWithData:data]];
}


- (id)initWithImage:(UIImage *)img {
    self = [super init];
    if (self != nil) {
        [self setType:kObjTypePicture];
        double scale = MIN(1, 200 / MAX([img size].width, [img size].height));
        if (scale < 1) {
            CGSize newSize = CGSizeMake([img size].width * scale, [img size].height * scale);
            img = [img resizedImage:newSize interpolationQuality:0.9];
        }

        [self setImage:img];
    }
    return self;
}

- (NSDictionary *)json {
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:2];
    [dict setObject:type forKey:@"type"];
    [dict setObject:[UIImageJPEGRepresentation(image, 0.9) encodeBase64] forKey:@"data"];
    
    return dict;
}

- (CGFloat)renderHeight {
    return [image size].height + 20;
}

- (UIView *)render {
    UIImageView* view = [[[UIImageView alloc] initWithImage:image] autorelease];
    [view setFrame:CGRectMake(10, 10, [image size].width + 10, [image size].height + 10)];
    return view;
}

@end

@implementation PictureTableCellView : FeedItemTableCell

@synthesize image, imageView;

- initWithImage: (UIImage*) img {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"pictureObjCell"];
    if (self != nil) {

        imageView = [[UIImageView alloc] initWithImage:image];
        [[self feedItemView] addSubview: imageView];
    }
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
/*    
    CGRect frame = CGRectMake(10, 10, [image size].width, [image size].height);
    
    CGRect cellFrame = [self frame];
    cellFrame.size.height = 40 + frame.size.height;
    [self setFrame:cellFrame];
    
    CGRect detailTextFrame = [[self detailTextLabel] frame];
    detailTextFrame.origin.y = frame.size.height + 15;
    [[self detailTextLabel] setFrame:detailTextFrame];
    
    [imageView setFrame: frame];*/
}

@end