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

#import "PersistentModelStore.h"
#import "MObj.h"
#import "MIdentity.h"
#import "Three20/Three20.h"
#import "MusubiStyleSheet.h"

@implementation AppDelegate

@synthesize window = _window, facebookLoginOperation, navController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //    [self setFacebook: [[[Facebook alloc] initWithAppId:kFacebookAppId andDelegate:self] autorelease]];
    //[TestFlight takeOff:@"xxx"];
    
    NSDate* showUIDate = [NSDate dateWithTimeIntervalSinceNow:1];
        
    DBSession* dbSession = [[DBSession alloc] initWithAppKey:@"" appSecret:@"" root:kDBRootAppFolder];
    [DBSession setSharedSession:dbSession];
    
    [Musubi sharedInstance];
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    
    [TTStyleSheet setGlobalStyleSheet:[[MusubiStyleSheet alloc] init]];
    
    // Pause on the loading screen for a bit, for awesomeness display reasons
    [NSThread sleepUntilDate:showUIDate];
    
    return YES;
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"received remote notification while running %@", userInfo);

    if( [userInfo objectForKey:@"local"] != NULL &&
       [userInfo objectForKey:@"amqp"] != NULL)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 6 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
            //TODO: good and racy
            NSNumber* amqp = (NSNumber*)[userInfo objectForKey:@"amqp"]; 
            int local = [APNPushManager tallyLocalUnread]; 
            [application setApplicationIconBadgeNumber:(amqp.intValue + local) ];
        });
    }    
}
- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {     
    NSLog(@"Error in registration. Error: %@", err);
}    
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {          
    [Musubi sharedInstance].apnDeviceToken = [deviceToken hexString];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [APNPushManager resetLocalUnreadInBackgroundTask:NO];

    
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

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];    
    UIViewController* vc = [storyboard instantiateInitialViewController];
    [self.window setRootViewController:vc];
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
