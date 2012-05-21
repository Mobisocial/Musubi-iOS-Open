//
//  AppDelegate.m
//  musubi
//
//  Created by Willem Bult on 10/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "FacebookAuth.h"
#import "Musubi.h"
#import "APNPushManager.h"
#import <DropboxSDK/DropboxSDK.h>
#import "NSData+HexString.h"
#import <DropboxSDK/DropboxSDK.h>

@implementation AppDelegate

@synthesize window = _window, facebookLoginOperation, navController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //    [self setFacebook: [[[Facebook alloc] initWithAppId:kFacebookAppId andDelegate:self] autorelease]];
    [TestFlight takeOff:@"xxx"];
    
    
    DBSession* dbSession = [[DBSession alloc] initWithAppKey:@"5ilykwqbdfy3wq6" appSecret:@"v5k6dskxe58ct68" root:kDBRootAppFolder];
    [DBSession setSharedSession:dbSession];
    
    [Musubi sharedInstance];
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"received remote notification while running %@", userInfo);

    ////TODO: do this only if amqp is not connectable, but we are still getting pushes
    //if( [[userInfo objectForKey:@"aps"] objectForKey:@"badge"] != NULL)
    //{
    //    NSNumber* badge = (NSNumber*)[[userInfo objectForKey:@"aps"] objectForKey:@"badge"]; 
    //    [application setApplicationIconBadgeNumber:badge.intValue];
    //}    
}
- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {     
    NSLog(@"Error in registration. Error: %@", err);
}    
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {          
    [Musubi sharedInstance].apnDeviceToken = [deviceToken hexString];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    //TODO: this is not quite right because the messages have not yet been downloaded
    // - one slightly better but still sucky thing would be to reset only if the AMQP thread 
    // was currently connected
    // - also could be better on exit in a quit background task
    NSString* deviceToken = [Musubi sharedInstance].apnDeviceToken;
    if(deviceToken) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            [APNPushManager clearUnread:deviceToken];
        });
    }
    
    [[Musubi sharedInstance].notificationCenter postNotification: [NSNotification notificationWithName:kMusubiNotificationAppOpened object:nil]];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

-(void)restart
{
    NSLog(@"Restarting UI");

    UITabBarController* tbController = (UITabBarController*) self.window.rootViewController;

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    
    UIViewController* vc = [storyboard instantiateInitialViewController];
//    [self.window addSubview:vc];
    [self.window setRootViewController:vc];

    /*
    for (UINavigationController* navC in tbController.viewControllers) {
        UIViewController* topVC = navC.topViewController;
        UIViewController* newVC = (UIViewController *)([[topVC.class alloc] initWithNibName:topVC.nibName bundle:nil]);
        
        [navC removeFromParentViewController];
        [navC.view removeFromSuperview];
        navC.viewControllers = [NSArray arrayWithObject: newVC];

        [tbController addChildViewController:navC];
    }*/
}

// Pre iOS 4.2 support
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        return YES;
    }
    
    return [facebookLoginOperation handleOpenURL:url];
}

// For iOS 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        return YES;
    }
    
    return [facebookLoginOperation handleOpenURL:url];
}

@end
