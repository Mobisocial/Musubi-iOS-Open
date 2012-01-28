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

- (UIView *)renderUpdate:(id<Update>)update
{
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
    }

    return nil;
}

- (int)renderHeightForUpdate:(id<Update>)update {

    if ([update isMemberOfClass:[StatusUpdate class]]) {
        CGSize size = [((StatusUpdate*) update).text sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:CGSizeMake(320, 1024) lineBreakMode:UILineBreakModeWordWrap];
        return size.height;
    } else if ([update isMemberOfClass:[PictureUpdate class]]) {
        return [((PictureUpdate*) update).image size].height + 20;
    }
    
    return 0;
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