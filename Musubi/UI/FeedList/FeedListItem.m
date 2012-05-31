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
//  FeedListItem.m
//  musubi
//
//  Created by Willem Bult on 5/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedListItem.h"
#import "FeedManager.h"
#import "MFeed.h"
#import "ObjManager.h"
#import "MObj.h"
#import "MIdentity.h"
#import "ObjFactory.h"
#import "StatusObj.h"
#import "Musubi.h"
#import "UIImage+Resize.h"

@implementation FeedListItem

@synthesize feed = _feed;
@synthesize unread = _unread;
@synthesize image = _image;

- (id)initWithFeed:(MFeed *)feed {
    self = [super init];
    if (self) {
        _feed = feed;
        FeedManager* feedMgr = [[FeedManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
        ObjManager* objMgr = [[ObjManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
        
        MObj* statusObj = [objMgr latestStatusObjInFeed:feed];
        if (statusObj) {
            StatusObj* obj = (StatusObj*) [ObjFactory objFromManagedObj:statusObj];
            self.text = obj.text;
        }
        /*
        for (MIdentity* ident in [feedMgr identitiesInFeed:feed]) {
            if (!ident.owned) {
                if(ident.musubiThumbnail) {
                    self.image = [UIImage imageWithData:ident.musubiThumbnail];
                    break;
                } else if (ident.thumbnail) {
                    self.image = [UIImage imageWithData:ident.thumbnail];
                    break;
                }
            }
        }*/
        
        self.image = [self imageForIdentities: [feedMgr identitiesInFeed:feed]];
        
        self.title = [feedMgr identityStringForFeed:feed];
        self.timestamp = [NSDate dateWithTimeIntervalSince1970:feed.latestRenderableObjTime];
        self.unread = feed.numUnread;
    }
    return self;
}

- (UIImage*) imageForIdentities: (NSArray*) identities {
    NSMutableArray* images = [NSMutableArray arrayWithCapacity:3];
    
    for (MIdentity* i in identities) {
        if (!i.owned) {
            UIImage* img = nil;
            
            if(i.musubiThumbnail) {
                img = [UIImage imageWithData:i.musubiThumbnail];                
            }
            if (img == nil && i.thumbnail) {
                img = [UIImage imageWithData:i.thumbnail];
            }
            
            if (img)
                [images addObject: img];
        }
        
        if (images.count > 3)
            break;
    }
    
    if (images.count > 1) {
        
        // Set up the context
        CGSize size = CGSizeMake(120, 120);
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();        
        
        // Set up the stroke buffer and settings
        CGPoint* pointBuffer = malloc(sizeof(CGPoint) * 2);
        CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
        CGContextSetLineWidth(context, 2.0);
        
        // The number of rows for the second column, and the x-pos offset for it
        int rows = images.count - 1;
        CGFloat colOffset = size.width - (size.width / MIN(3, rows+1)) + 1; // add 1 for the line
        
        // The left column image is the largest, and placed at (0,0)
        UIImage* leftImg = [self image:[images objectAtIndex:0] centeredAndResizedTo:CGSizeMake(colOffset, size.height)];
        [leftImg drawAtPoint: CGPointMake(0, 0)];
        
        // Draw a line to the right of it
        pointBuffer[0] = CGPointMake(colOffset-1, 0);
        pointBuffer[1] = CGPointMake(colOffset-1, size.height);
        CGContextStrokeLineSegments(context, pointBuffer, 2);
        
        // Calc the size of the small images in the right column
        CGSize colImgBounds = CGSizeMake(size.width - colOffset, size.height / rows);
        
        // Draw the right column
        for (int row=0; row<rows; row++) {
            // Resize/crop the image and draw it
            UIImage* curImg = ((UIImage*)[images objectAtIndex:row + 1]);            
            UIImage* cropped = [self image:curImg centeredAndResizedTo:colImgBounds];          
            [cropped drawAtPoint: CGPointMake(colOffset, colImgBounds.height * row)];
            
            // Draw a line under it if we have more coming
            if (row<rows-1) {                
                pointBuffer[0] = CGPointMake(colOffset-1, colImgBounds.height * (row + 1) - 1);
                pointBuffer[1] = CGPointMake(size.width, colImgBounds.height * (row + 1) - 1);
                CGContextStrokeLineSegments(context, pointBuffer, 2);
            }
        }
        
        // Clear and return
        UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return result;        
    } else if (images.count == 1) {
        return [images objectAtIndex:0];
    }
     
    return nil;
}


- (UIImage*) image: (UIImage*) img  centeredAndResizedTo: (CGSize) size {
    // Aspect scales the image to the selected bounds (filling) and then cuts out the center that matches the selected bounds
    // Result is the max available center portion of the image that fits in the bounds
    
    int resizeBound = MAX(size.height, size.width);    
    UIImage* resized = [img resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(resizeBound, resizeBound) interpolationQuality:0.8];            
    
    CGPoint offset = CGPointMake((resizeBound - size.width)/2, (resizeBound - size.height)/2);
    return [resized croppedImage:CGRectMake(offset.x, offset.y, size.width, size.height)]; 
}

@end
