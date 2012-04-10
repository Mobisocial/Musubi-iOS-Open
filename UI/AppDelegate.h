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

@property (retain, nonatomic) UIWindow *window;
@property (retain, nonatomic) UINavigationController* navController;

// Facebook SingleSignOn always calls back the appDelegate, so we need a reference to the login
@property (nonatomic, assign) FacebookLoginOperation* facebookLoginOperation;

@end
