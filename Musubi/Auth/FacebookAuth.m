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
//  FacebookAuth.m
//  Musubi
//
//  Created by Willem Bult on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FacebookAuth.h"
#import "AppDelegate.h"
#import "AccountAuthManager.h"
#import "MAccount.h"
#import "Musubi.h"

@implementation FacebookAuthManager

@synthesize facebook;

- (id) init {
    return [self initWithDelegate:nil];
}

- (id) initWithDelegate: (id<FBSessionDelegate>) d {
    self = [super init];
    if (self) {
        [self setFacebook: [[Facebook alloc] initWithAppId:kFacebookAppId andDelegate:d]];
    
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults objectForKey:@"FBAccessTokenKey"] 
            && [defaults objectForKey:@"FBExpirationDateKey"]) {
            facebook.accessToken = [defaults objectForKey:@"FBAccessTokenKey"];
            facebook.expirationDate = [defaults objectForKey:@"FBExpirationDateKey"];
        }
    }

    return self;
}

- (void)fbDidLogin {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[facebook accessToken] forKey:@"FBAccessTokenKey"];
    [defaults setObject:[facebook expirationDate] forKey:@"FBExpirationDateKey"];
    [defaults synchronize];
}

- (NSString *)activeAccessToken {
    if ([facebook isSessionValid]) {
        return [facebook accessToken];
    }
    return nil;
}

@end

@implementation FacebookConnectOperation

@synthesize facebookMgr, manager;

- (id)initWithManager:(AccountAuthManager *)m {
    self = [super init];
    if (self) {
        [self setFacebookMgr: [[FacebookAuthManager alloc] initWithDelegate: self]];
        [self setManager: m];
    }
    
    return self;
}

- (void)fbDidLogin {
    [facebookMgr fbDidLogin];
}

- (NSArray *)facebookAtIndexes:(NSIndexSet *)indexes {
    return nil;
}

- (void)fbDidLogout {
    
}

- (void)fbDidNotLogin:(BOOL)cancelled {
    
}

- (void)fbSessionInvalidated {
    
}

- (void)fbDidExtendToken:(NSString *)accessToken expiresAt:(NSDate *)expiresAt {
}

@end


@implementation FacebookCheckValidOperation

- (void)main {
    if ([facebookMgr.facebook isSessionValid]) {
        [facebookMgr.facebook requestWithGraphPath:@"me" andDelegate:self];
    } else {
        [manager onAccount:kAccountTypeFacebook isValid:NO];
    }
}

- (void)request:(FBRequest *)request didLoad:(id)result {
    BOOL valid = result != nil && [result objectForKey:@"id"] != nil;
    [manager onAccount:kAccountTypeFacebook isValid:valid];
}

@end


@implementation FacebookLoginOperation

- (void)main {
    finished = NO;
    
//    if (![facebook isSessionValid]) {
        // App delegate is the one who gets called back after login, needs a reference here
        [((AppDelegate*) [[UIApplication sharedApplication] delegate]) setFacebookLoginOperation: self];

        NSArray *permissions = [[[NSArray alloc] initWithObjects:
                                 @"read_friendlists", 
                                 @"email",
                                 @"offline_access",
                                 @"publish_stream",
                                 nil] autorelease];
        [facebookMgr.facebook authorize:permissions];
//    }
}

// Because the SSO runs asynchronously, we have to make sure the thread doesn't get destroyed until we're completely done
- (BOOL)isFinished {
    return [super isFinished] && finished;
}

- (BOOL)handleOpenURL:(NSURL *)url {
    // Remove the reference
    [((AppDelegate*) [[UIApplication sharedApplication] delegate]) setFacebookLoginOperation: nil];
    return [facebookMgr.facebook handleOpenURL:url];
}

- (void)fbDidLogin {
    [super fbDidLogin];
    
    // Request "me" from Graph API to create the account with
    [facebookMgr.facebook requestWithGraphPath:@"me" andDelegate:self];
}

- (void)request:(FBRequest *)request didLoad:(id)result {
    if (result != nil && [result objectForKey:@"id"] != nil) {
        MAccount* account = [manager storeAccount:kAccountTypeFacebook name:[result objectForKey:@"email"] principal:[result objectForKey:@"id"]];
        [manager onAccount:kAccountTypeFacebook isValid:account != nil];
        
        if (account) {
            [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationFacebookFriendRefresh object:nil];
        }
    } else {
        [manager onAccount:kAccountTypeFacebook isValid:NO];
    }
    
    finished = YES;
}

@end
