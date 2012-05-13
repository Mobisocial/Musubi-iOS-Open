//
//  AppDelegate.h
//  musubi
//
//  Created by Willem Bult on 10/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FacebookLoginOperation;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property ( nonatomic) UIWindow *window;
@property ( nonatomic) UINavigationController* navController;

// Facebook SingleSignOn always calls back the appDelegate, so we need a reference to the login
@property (nonatomic, weak) FacebookLoginOperation* facebookLoginOperation;

- (void) restart;

@end
