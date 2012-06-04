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
#import "PictureObj.h"
#import "Three20Core/NSDateAdditions.h"

@interface SneakyDate : NSObject
- (SneakyDate*)initWithDate:(NSDate*)date andNewest:(NSDate*)newest andOldest:(NSDate*)oldest;
@end

@implementation SneakyDate {
    NSDate* _newest;
    NSDate* _oldest;
    NSDate* _mine;
}

- (SneakyDate *)initWithDate:(NSDate *)date andNewest:(NSDate *)newest andOldest:(NSDate *)oldest
{
    self = [super init];
    if(!self) 
         return nil;
    
    _mine = date;
    _newest = newest;
    _oldest = oldest;
    
    return self;
}

- (NSString*)formatShortTime {
    NSTimeInterval diff = abs([_mine timeIntervalSinceNow]);
    
    if (diff < TT_DAY * 7) {
        return [_mine formatTime];
        
    } else {
        static NSDateFormatter* formatter = nil;
        if (nil == formatter) {
            formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = TTLocalizedString(@"M/d/yy", @"Date format: 7/27/09");
            formatter.locale = TTCurrentLocale();
        }
        return [formatter stringFromDate:_mine];
    }
}
@end


static NSMutableDictionary* sContactImages;



@implementation FeedListItem {
    int32_t _unread;
}
+ (NSMutableDictionary*)contactImages {
    if(!sContactImages)
        sContactImages = [NSMutableDictionary dictionary];
    return sContactImages;
}

@synthesize feed = _feed;
@synthesize image = _image;
@synthesize obj = _obj;
@synthesize start = _start;
@synthesize end = _end;
@synthesize picture = _picture;

- (id)initWithFeed:(MFeed *)feed after:(NSDate*)after before:(NSDate*)before {
    self = [super init];
    if(!self)
        return nil;
    _feed = feed;
    FeedManager* feedMgr = [[FeedManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    ObjManager* objMgr = [[ObjManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
    
    self.title = [feedMgr identityStringForFeed:feed];
    self.timestamp = [[SneakyDate alloc] initWithDate:[NSDate dateWithTimeIntervalSince1970:feed.latestRenderableObjTime] andNewest:after andOldest:before];

    _obj = [objMgr latestObjOfType:kObjTypeStatus inFeed:feed after:nil before:nil];
    if (_obj) {
        StatusObj* obj = (StatusObj*) [ObjFactory objFromManagedObj:_obj];
        self.text = obj.text;
    }
    MObj* picture = [objMgr latestObjOfType:kObjTypePicture inFeed:feed after:nil before:_obj.timestamp];
    if (picture) {
        PictureObj* obj = (PictureObj*) [ObjFactory objFromManagedObj:picture];
        _obj = picture;
        self.picture =  [UIImage imageWithData:obj.raw];
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
    
    NSArray* order = _obj ? [NSArray arrayWithObject:_obj.identity] : nil;
    self.image = [self imageForIdentities: [feedMgr identitiesInFeed:feed] preferredOrder:order];
    
    _unread = feed.numUnread;
    self.start = after;
    self.end = before;
    return self;
}

- (int32_t)unread {
    //update the unread count on the old items if need be
    if(_start && _unread) {
        _unread = _feed.numUnread;
    }
    return _unread;
}
- (UIImage*) imageForIdentities: (NSArray*) identities preferredOrder:(NSArray*)order {
    NSMutableArray* selected = [NSMutableArray arrayWithCapacity:4];
    
    NSMutableArray* images = [NSMutableArray arrayWithCapacity:4];

    for (MIdentity* i in order) {
        if (selected.count > 3)
            break;
       
        if(i.musubiThumbnail || i.thumbnail) {
            [selected addObject:i];
        }
        
    }
    for (MIdentity* i in identities) {
        BOOL dupe = NO;
        for(MIdentity* j in order) {
            if([j isEqual:i]) {
                dupe = YES;
                break;
            }
        }
        if(dupe)
            continue;
        if (selected.count > 3)
            break;
        if(i.musubiThumbnail || i.thumbnail) {
            [selected addObject:i];
        }
        
    }
    NSMutableArray* selected_ids = [NSMutableArray arrayWithCapacity:selected.count];
    for(MIdentity* i in selected) {
        [selected_ids addObject:i.objectID];
    }
    
    NSMutableDictionary* feedImageCache = [FeedListItem contactImages];
    UIImage * cachedImage = [feedImageCache objectForKey:selected_ids];
    //TODO: profile change invalidation
    if(cachedImage)
        return cachedImage;
    

    for (MIdentity* i in selected) {
        UIImage* img = nil;
        
        if(i.musubiThumbnail) {
            img = [UIImage imageWithData:i.musubiThumbnail];                
        }
        if (!img && i.thumbnail) {
            img = [UIImage imageWithData:i.thumbnail];
        }
        
        if (img)
            [images addObject: img];
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
        UIImage* leftImg = [(UIImage*)[images objectAtIndex:0] centerFitAndResizeTo:CGSizeMake(colOffset, size.height)];
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
            UIImage* cropped = [curImg centerFitAndResizeTo:colImgBounds];          
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
        free(pointBuffer);
        
        [feedImageCache setObject:result forKey:selected_ids];
        
        return result;        
    } else if (images.count == 1) {
        return [images objectAtIndex:0];
    }
     
    return nil;
}


@end
