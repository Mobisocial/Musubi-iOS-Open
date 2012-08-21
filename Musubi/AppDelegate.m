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
#import "GoogleAuth.h"

#import "MusubiShareKitConfigurator.h"
#import "SHKConfiguration.h"
#import "SHKFacebook.h"
#import "SHK.h"
#import "MusubiAnalytics.h"
#import "ObjRegistry.h"

#import "Three20/Three20.h"
#import "MusubiStyleSheet.h"
#import "SettingsViewController.h"

#import "IdentityManager.h"
#import "FeedListViewController.h"
#import "StatusObj.h"
#import "NSData+Base64.h"

static const NSInteger kGANDispatchPeriodSec = 60;

@implementation AppDelegate

@synthesize window = _window, navController;
@synthesize facebookIdentityUpdater, googleIdentityUpdater, facebookLoginOperation;

Obj *clipboardObj;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [ObjRegistry registerObjs];
    [[Musubi sharedInstance] onAppLaunch];
    
    [TTStyleSheet setGlobalStyleSheet:[[MusubiStyleSheet alloc] init]];

    //    [self setFacebook: [[[Facebook alloc] initWithAppId:kFacebookAppId andDelegate:self] autorelease]];
    //[TestFlight takeOff:@"xxx"];

    [self prepareAnalytics];

    NSDate* showUIDate = [NSDate dateWithTimeIntervalSinceNow:1];
        
    DBSession* dbSession = [[DBSession alloc] initWithAppKey:@"" appSecret:@"" root:kDBRootAppFolder];
    [DBSession setSharedSession:dbSession];
    
    
    MusubiShareKitConfigurator *configurator = [[MusubiShareKitConfigurator alloc] init];
    [SHKConfiguration sharedInstanceWithConfigurator:configurator];
    [SHK flushOfflineQueue];

    
    self.facebookIdentityUpdater = [[FacebookIdentityUpdater alloc] initWithStoreFactory: [Musubi sharedInstance].storeFactory];
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:kFacebookIdentityUpdaterFrequency target:self.facebookIdentityUpdater selector:@selector(refreshFriendsIfNeeded) userInfo:nil repeats:YES] forMode:NSDefaultRunLoopMode];
    
    self.googleIdentityUpdater = [[GoogleIdentityUpdater alloc] initWithStoreFactory: [Musubi sharedInstance].storeFactory];
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:kGoogleIdentityUpdaterFrequency target:self.googleIdentityUpdater selector:@selector(refreshFriendsIfNeeded) userInfo:nil repeats:YES] forMode:NSDefaultRunLoopMode];
      
    [[Musubi sharedInstance].identityProvider registerProvider:[[EmailAphidAuthProvider alloc] init]];
    [[Musubi sharedInstance].identityProvider registerProvider:[[FacebookAphidAuthProvider alloc] init]];
    [[Musubi sharedInstance].identityProvider registerProvider:[[GoogleAphidAuthProvider alloc] init]];
    
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
    UIStoryboard *storyboard;
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)) {
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil];
    }
    else {
        storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPad" bundle:nil];
    }
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
        [((SettingsViewController*) self.window.rootViewController.childViewControllers.lastObject).tableView reloadData];
        [((SettingsViewController*) self.window.rootViewController.childViewControllers.lastObject).tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
        [((SettingsViewController*) self.window.rootViewController.childViewControllers.lastObject).tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:2 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
        return YES;
    }

    if ([url.scheme hasPrefix:kMusubiUriScheme]) {
        if ([url.path hasPrefix:@"/intro/"]) {
            // n, t, p
            NSArray *components = [[url query] componentsSeparatedByString:@"&"];
            NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
            for (NSString *component in components) {
                [parameters setObject:[[component componentsSeparatedByString:@"="] objectAtIndex:0] forKey:[[component componentsSeparatedByString:@"="] objectAtIndex:1]];
            }
            NSString *idName = [parameters objectForKey:@"n"];
            NSString *idTypeString = [parameters objectForKey:@"t"];
            NSString *idValue = [parameters objectForKey:@"p"];

            if (idValue != nil && idTypeString != nil) {
                int idType = [idTypeString intValue];
                if (idName == nil) {
                    idName = idValue;
                }

                BOOL identityAdded = NO;
                BOOL profileDataChanged = NO;
                IdentityManager* im = [[IdentityManager alloc] initWithStore:[Musubi sharedInstance].mainStore];
                [im ensureIdentityWithType:idType andPrincipal:idValue andName:idName identityAdded:&identityAdded profileDataChanged:&profileDataChanged];
            }

            return YES;
        } else if ([url.host isEqualToString:@"share"]) {
            NSString *b64String = [url.path substringFromIndex:1];
            NSData *jsonData = [b64String decodeBase64];
            NSDictionary* json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];

            if (json != nil) {
                clipboardObj = nil; // TODO: Parse the obj
                UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Sharing data" message:@"Click 'Okay' and choose a conversation for sharing, or click cancel to discard the data." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Okay", nil];
                [alert show];

                return YES;
            }
        }
    }
    NSLog(@"No one touched %@", [url path]);
    return [[Musubi sharedInstance] handleURL:url fromSourceApplication:sourceApplication];
}

- (void)alertView:(UIAlertView *)alertView
clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        UINavigationController* nav = (UINavigationController*)self.window.rootViewController;
        [nav popToRootViewControllerAnimated:YES];
        FeedListViewController *feedList = (FeedListViewController*) nav.topViewController;
        [feedList setClipboardObj: clipboardObj];
        clipboardObj = nil;
    }
}

@end

@implementation NonAnimatedSegue

//@synthesize appDelegate = _appDelegate;

-(void) perform{
    [[[self sourceViewController] navigationController] pushViewController:[self destinationViewController] animated:NO];
}
@end
