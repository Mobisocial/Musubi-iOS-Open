//
//  ObjRenderer.m
//  musubi
//
//  Created by Willem Bult on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ObjRenderer.h"
#import "StatusUpdate.h"
#import "JoinNotificationObj.h"
#import "PictureUpdate.h"

@implementation ObjRenderer

- (UIView *)renderUpdate:(id<Update>)update
{
    if ([update isMemberOfClass:[StatusUpdate class]]) {
        NSString* text;
        
        if ([update isMemberOfClass:[StatusUpdate class]])
            text = ((StatusUpdate*) update).text;
        
        UILabel* label = [[UILabel alloc] init];
        [label setFont: [UIFont systemFontOfSize:15]];
        [label setText: text];
        [label setLineBreakMode:UILineBreakModeWordWrap];
        
        CGSize size = CGSizeMake(320, [self renderHeightForUpdate:update]);
        [label setFrame:CGRectMake(0, 0, size.width, size.height)];
        
        return label;
    } else if ([update isMemberOfClass:[PictureUpdate class]]) {
        UIImage* image = ((PictureUpdate*) update).image;
        UIImageView* view = [[[UIImageView alloc] initWithImage:image] autorelease];
        [view setFrame:CGRectMake(10, 10, [image size].width + 10, [image size].height + 10)];
        return view;
    }

    return nil;
}

- (int)renderHeightForUpdate:(id<Update>)update
{
    if ([update isMemberOfClass:[StatusUpdate class]]) {
        CGSize size = [((StatusUpdate*) update).text sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:CGSizeMake(320, 1024) lineBreakMode:UILineBreakModeWordWrap];
        return size.height;
    } else if ([update isMemberOfClass:[PictureUpdate class]]) {
        return [((PictureUpdate*) update).image size].height + 20;
    }
    
    return 0;
}

@end
