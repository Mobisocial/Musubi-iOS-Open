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
//  GoogleAuth.m
//  musubi
//
//  Created by Willem Bult on 3/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GoogleAuth.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "SBJSON.h"
#import "MAccount.h"
#import "Musubi.h"
#import "AccountAuthManager.h"

static GTMOAuth2Authentication* active;

@implementation GoogleAuthManager

- (GTMOAuth2Authentication*) activeAuth {
    if (active != nil)
        return active;
    else {
        GTMOAuth2Authentication *auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kGoogleKeyChainItemName clientID:kGoogleClientId clientSecret:kGoogleClientSecret];
        
        if ([auth canAuthorize]) {
            NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.googleapis.com/oauth2/v1/userinfo"]];
            [auth authorizeRequest:req
                 completionHandler:^(NSError *error) {
                     CFRunLoopStop(CFRunLoopGetCurrent());
                 }];

            CFRunLoopRun();
            active = [auth retain];
        }
        
        return active;
    }
    
    return nil;
}

- (NSString *)activeAccessToken {
    return [self activeAuth].accessToken;
}

- (void) didLoginWith: (GTMOAuth2Authentication*) auth {
    active = [auth retain];
}


@end

@implementation GoogleOAuthOperation

@synthesize manager, googleMgr;

- (id)initWithManager:(AccountAuthManager *)m {
    self = [super init];
    if (self) {
        [self setManager:m];
        [self setGoogleMgr: [[GoogleAuthManager alloc] init]];
    }
    return self;
}

- (void) fetchUserInfo {
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.googleapis.com/oauth2/v1/userinfo"]];
    
    GTMOAuth2Authentication* auth = [googleMgr activeAuth];
    [auth authorizeRequest:req
                  delegate:self
         didFinishSelector:@selector(authentication:request:finishedWithError:)];
}

- (void)authentication:(GTMOAuth2Authentication *)auth
               request:(NSMutableURLRequest *)request
     finishedWithError:(NSError *)error {
}


@end


@implementation GoogleOAuthCheckValidOperation

- (void)main {
    [manager onAccount:kAccountTypeGoogle isValid:[googleMgr activeAccessToken] != nil];
}

@end


@implementation GoogleOAuthLoginOperation {
    CFRunLoopRef runLoop;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)start {
    [super start];
    [self openDialog];
    
    CFRunLoopRun(); // Avoid thread exiting
    runLoop = CFRunLoopGetCurrent();
}

- (void)finish
{
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] dismissModalViewControllerAnimated:YES];
    CFRunLoopStop(runLoop);
}

- (void) openDialog {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(openDialog) withObject:nil waitUntilDone:YES];
        return;
    }
    
    GTMOAuth2ViewControllerTouch* vc = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGoogleOAuthScope clientID:kGoogleClientId clientSecret:kGoogleClientSecret keychainItemName:kGoogleKeyChainItemName delegate:self finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    
    [vc setBackButton:[UIButton buttonWithType:UIButtonTypeRoundedRect]];
    
    UIViewController* root = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    UINavigationController* settingsNavController = (UINavigationController*)[root.childViewControllers objectAtIndex:1];
    UIViewController* settingsViewController = [settingsNavController topViewController];
    
    //NSLog(@"Children: %@", root.tabBarController.childViewControllers);
//    [root presentModalViewController:vc animated:YES];
//    [root pushViewController:vc animated:YES];
    
    [settingsNavController pushViewController:vc animated:YES];
}

- (void) viewController: (GTMOAuth2ViewControllerTouch*) vc finishedWithAuth: (GTMOAuth2Authentication*) auth error: (NSError*) error {
    if (error == nil) {
        [googleMgr didLoginWith:auth];
        [self fetchUserInfo];
    } else {
        NSLog(@"Error: %@", error);
        [self finish];        
    }
}

- (void) fetchUserInfo {
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.googleapis.com/oauth2/v1/userinfo"]];
    
    GTMOAuth2Authentication* auth = [googleMgr activeAuth];
    [auth authorizeRequest:req
                  delegate:self
         didFinishSelector:@selector(authentication:request:finishedWithError:)];
}

- (void)authentication:(GTMOAuth2Authentication *)auth
               request:(NSMutableURLRequest *)request
     finishedWithError:(NSError *)error {
    if (error != nil) {
        // Authorization failed
        NSLog(@"Error: %@", error);
        [self finish];
    } else {
        // Authorization succeeded
        NSURLConnection* conn = [NSURLConnection connectionWithRequest:request delegate:self];
        [conn start];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSString* json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    SBJsonParser* parser = [[[SBJsonParser alloc] init] autorelease];
    NSDictionary* dict = [parser objectWithString:json];
    
    if (dict != nil && [dict objectForKey:@"email"] != nil) {
        NSString* accountName = [dict objectForKey:@"email"];
        MAccount* account = [manager storeAccount:kAccountTypeGoogle name:accountName principal:[dict objectForKey:@"email"]];
        [manager onAccount:kAccountTypeGoogle isValid:account != nil];
        
        if (account) {
            [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationGoogleFriendRefresh object:nil];
        }
    } else {
        [manager onAccount:kAccountTypeGoogle isValid:NO];
    }
    
    [self finish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Error: %@", error);
    [self finish];
}

@end