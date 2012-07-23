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
#import "Musubi.h"
#import "NSData+HexString.h"
#import <DropboxSDK/DropboxSDK.h>

#import "FacebookIdentityUpdater.h"
#import "GoogleIdentityUpdater.h"
xxx#import "FacebookAuth.h"

#import "MusubiShareKitConfigurator.h"
#import "SHKConfiguration.h"
#import "SHKFacebook.h"
#import "SHK.h"
#import "MusubiAnalytics.h"

#define kMusubiUriScheme @"musubi"
static const NSInteger kGANDispatchPeriodSec = 60;

@implementation AppDelegate

@synthesize window = _window, navController;
@synthesize facebookIdentityUpdater, googleIdentityUpdater, facebookLoginOperation;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[Musubi sharedInstance] onAppLaunch];

    //    [self setFacebook: [[[Facebook alloc] initWithAppId:kFacebookAppId andDelegate:self] autorelease]];
    //[TestFlight takeOff:@"xxx"];

    [self prepareAnalytics];

    NSDate* showUIDate = [NSDate dateWithTimeIntervalSinceNow:1];
        
    DBSession* dbSession = [[DBSession alloc] initWithAppKey:@"" appSecret:@"" root:kDBRootAppFolder];
    [DBSession setSharedSession:dbSession];
    
    self.facebookIdentityUpdater = [[FacebookIdentityUpdater alloc] initWithStoreFactory: [Musubi sharedInstance].storeFactory];
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:kFacebookIdentityUpdaterFrequency target:self.facebookIdentityUpdater selector:@selector(refreshFriendsIfNeeded) userInfo:nil repeats:YES] forMode:NSDefaultRunLoopMode];
    
    self.googleIdentityUpdater = [[GoogleIdentityUpdater alloc] initWithStoreFactory: [Musubi sharedInstance].storeFactory];
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:kGoogleIdentityUpdaterFrequency target:self.googleIdentityUpdater selector:@selector(refreshFriendsIfNeeded) userInfo:nil repeats:YES] forMode:NSDefaultRunLoopMode];
      
    
    return YES;
}

- (void) prepareAnalytics {
    [[GANTracker sharedTracker] startTrackerWithAccountID:@""
                                           dispatchPeriod:kGANDispatchPeriodSec
                                                 delegate:nil];
    
    NSError *error;
    if (![[GANTracker sharedTracker] setCustomVariableAtIndex:1
                                                         name:@"iPhone1"
                                                        value:@"iv1"
                                                    withError:&error]) {
        // Handle error here
    }

    if (![[GANTracker sharedTracker] trackPageview:kAnalyticsPageAppEntryPoint
                                         withError:&error]) {
        // Handle error here
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[Musubi sharedInstance] onRemoteNotification: userInfo];
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {     
    NSLog(@"Error in registration. Error: %@", err);
}    

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {          
    [Musubi sharedInstance].apnDeviceToken = [deviceToken hexString];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[Musubi sharedInstance] onAppDidBecomeActive];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[Musubi sharedInstance] onAppWillResignActive];
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

// For iOS 4.2+ support
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    NSString* facebookPrefix = [NSString stringWithFormat:@"fb%@", SHKCONFIG(facebookAppId)];
    if ([url.scheme hasPrefix:facebookPrefix]) {
        BOOL shk, fb;
        shk = [SHKFacebook handleOpenURL:url];
        fb = [facebookLoginOperation handleOpenURL:url];
        
        return shk && fb;
    }
    
    if ([[DBSession sharedSession] handleOpenURL:url]) {
        return YES;
    }

    if ([url.scheme hasPrefix:kMusubiUriScheme]) {
        if ([url.path hasPrefix:@"/intro/"]) {
            return YES;
        }
    }

    return [[Musubi sharedInstance] handleURL:url fromSourceApplication:sourceApplication];
}

@end

@implementation NonAnimatedSegue

//@synthesize appDelegate = _appDelegate;

-(void) perform{
    [[[self sourceViewController] navigationController] pushViewController:[self destinationViewController] animated:NO];
}
@end
