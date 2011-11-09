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
//  PictureObj.h
//  musubi
//
//  Created by Willem Bult on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SignedObj.h"
#import "NSData+Base64.h"
#import "UIImage+Resize.h"
#import "FeedItemTableCell.h"

static NSString* kObjTypePicture = @"picture";

@interface PictureObj : SignedObj {
    UIImage* image;
}

@property (nonatomic,retain) UIImage* image;

- (id) initWithData: (NSData *) data;
- (id) initWithImage: (UIImage *) img;
@end


@interface PictureTableCellView : FeedItemTableCell {
    UIImage* image;
    UIImageView* imageView;
}

@property (nonatomic,retain) IBOutlet UIImage* image;
@property (nonatomic,retain) IBOutlet UIImageView* imageView;
- initWithImage: (UIImage*) img;
@end
