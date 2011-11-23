//
//  HTMLFeedViewController.h
//  musubi
//
//  Created by Willem Bult on 11/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Feed.h"
#import "App.h"
#import "URLCommand.h"
#import "Musubi.h"
#import "SBJson.h"
#import "NSData+Base64.h"

@interface HTMLAppViewController : UIViewController<UIWebViewDelegate, MusubiFeedListener> {
    App* app;
    
    @private
    
    NSMutableDictionary* updates;
    IBOutlet UIWebView* webView;
    
}

@property (nonatomic,retain) App* app;

@end
