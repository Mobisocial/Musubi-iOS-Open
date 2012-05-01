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
//  ObjRenderer.m
//  musubi
//
//  Created by Willem Bult on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ObjRenderer.h"
#import "Obj.h"
#import "StatusObj.h"
#import "IntroductionObj.h"
#import "PictureObj.h"
#import "StatusObjItem.h"

#define kFeedItemTableCellWidth 267

@implementation ObjRenderer

- (UIView *)renderObj:(Obj*)obj
{
    /*
   if ([update isMemberOfClass:[StatusUpdate class]]) {
       NSString* text = ((StatusUpdate*) update).text;
        
       UILabel* label = [[[UILabel alloc] init] autorelease];
       [label setNumberOfLines:0];
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
   } else if ([update isMemberOfClass:[AppStateUpdate class]]) {
       NSString* html = [[[update obj] data] objectForKey:@"html"];
       
       UIWebView* webView = [[[UIWebView alloc] init] autorelease];
       [webView loadHTMLString:html baseURL:nil];        
       [webView setFrame:CGRectMake(0, 0, 320, 0)];
       ((UIScrollView*)[webView.subviews objectAtIndex:0]).bounces = NO;
       
       return webView;
    }*/
    
    if ([obj isMemberOfClass:[StatusObj class]]) {
        StatusObjItem* cell = [[StatusObjItem alloc] init];
        [cell setText: ((StatusObj*) obj).text];
    } else {
        StatusObjItem* cell = [[StatusObjItem alloc] init];
        [cell setText: @"Unknown message type"];
    }    
    
    /*
     if ([obj isMemberOfClass:[StatusObj class]]) {
     NSString* text = ((StatusObj*) obj).text;
     
     UILabel* label = [[[UILabel alloc] init] autorelease];
     [label setNumberOfLines:0];
     [label setFont: [UIFont systemFontOfSize:15]];
     [label setText: text];
     [label setLineBreakMode:UILineBreakModeWordWrap];
     
     CGSize size = CGSizeMake(kFeedItemTableCellWidth, [self renderHeightForObj: obj]);
     [label setFrame:CGRectMake(0, 0, size.width, size.height)];
     
     return label;
     } else if ([obj isMemberOfClass:[PictureObj class]]) {
     UIImage* image = ((PictureObj*) obj).image;
     UIImageView* view = [[[UIImageView alloc] initWithImage:image] autorelease];
     [view setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
     [view setContentMode:UIViewContentModeScaleAspectFit];
     [view setFrame:CGRectMake(0, 10, kFeedItemTableCellWidth, (kFeedItemTableCellWidth / image.size.width) * image.size.height)];
     return view;
     } else {
     UILabel* label = [[[UILabel alloc] init] autorelease];
     [label setFont: [UIFont systemFontOfSize:15]];
     [label setText: @"Error: failed to render"];
     
     CGSize size = CGSizeMake(kFeedItemTableCellWidth, [self renderHeightForObj:obj]);
     [label setFrame:CGRectMake(0, 0, size.width, size.height)];
     
     return label;
     }*/
}

- (int)renderHeightForObj:(Obj*)obj {

    if ([obj isMemberOfClass:[StatusObj class]]) {
        CGSize size = [((StatusObj*) obj).text sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:CGSizeMake(kFeedItemTableCellWidth, 1024) lineBreakMode:UILineBreakModeWordWrap];
        return size.height;
    } else if ([obj isMemberOfClass:[PictureObj class]]) {
        UIImage* image = ((PictureObj*) obj).image;
        return (kFeedItemTableCellWidth / image.size.width) * image.size.height + 20;
    } else {
        return 0;
    }
}

@end


/*
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
 #import "AppStateUpdate.h"
 
 @implementation ObjRenderer
 
 - (id)init {
 self = [super init];
 if (self != nil) {
 views = [[NSMutableDictionary alloc] init];
 }
 return self;
 }
 
 - (UIView *)viewForUpdate:(id<Update>)update
 {
 if ([update isMemberOfClass:[StatusUpdate class]]) {
 NSString* text;
 
 if ([update isMemberOfClass:[StatusUpdate class]])
 text = ((StatusUpdate*) update).text;
 
 UILabel* label = [[UILabel alloc] init];
 [label setFont: [UIFont systemFontOfSize:15]];
 [label setText: text];
 [label setLineBreakMode:UILineBreakModeWordWrap];
 
 CGSize size = [((StatusUpdate*) update).text sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:CGSizeMake(320, 1024) lineBreakMode:UILineBreakModeWordWrap];
 [label setFrame:CGRectMake(0, 0, size.width, size.height)];
 
 return label;
 } else if ([update isMemberOfClass:[PictureUpdate class]]) {
 UIImage* image = ((PictureUpdate*) update).image;
 UIImageView* view = [[[UIImageView alloc] initWithImage:image] autorelease];
 [view setFrame:CGRectMake(10, 10, [image size].width + 10, [image size].height + 10)];
 return view;
 } else if ([update isMemberOfClass:[AppStateUpdate class]]) {
 NSString* html = [[[update obj] data] objectForKey:@"html"];
 
 UIWebView* webView = [[UIWebView alloc] initWithFrame:CGRectMake(0,0,320,0)];
 
 [webView setDelegate:self];
 [webView loadHTMLString:html baseURL:nil];

return webView;
}

return nil;
}

- (UIView *)renderUpdate:(id<Update>)update
{
    UIView* view = [views objectForKey:update];
    [views removeObjectForKey:update];
    
    return view;
}

- (int)renderHeightForUpdate:(id<Update>)update
{
    UIView* view = [self viewForUpdate:update];
    [views setObject: view forKey:update];
    
    if (view != nil) {
        return [view frame].size.height;
    } else {
        return 0;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *output = [webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('this').offsetHeight;"];
    NSLog(@"Webview finished loading! %@", output);
    [webView setFrame:CGRectMake(0, 0, 320, [output floatValue])];
}

@end
*/