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
//  FacebookAuth.h
//  Musubi
//
//  Created by Willem Bult on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Facebook.h"

#define kFacebookAppId @""

@class MAccount, AccountAuthManager, SettingsViewController;

@interface FacebookAuthManager : NSObject<FBSessionDelegate> {
    Facebook* facebook;
}

@property (nonatomic) Facebook* facebook;

- (id) initWithDelegate: (id<FBSessionDelegate>) d;
- (void) fbDidLogin;

- (NSString*) activeAccessToken;

@end

// Abstract Facebook operation
@interface FacebookConnectOperation : NSOperation<FBSessionDelegate> {
    AccountAuthManager* manager;
    FacebookAuthManager* facebookMgr;
}

@property (nonatomic) AccountAuthManager* manager;
@property (nonatomic) FacebookAuthManager* facebookMgr;

- (id) initWithManager: (AccountAuthManager*) m;

@end


// Operation to check the facebook auth token validity
@interface FacebookCheckValidOperation : FacebookConnectOperation <FBRequestDelegate>
@end

// Operation to create a new account by connecting to FB
@interface FacebookLoginOperation : FacebookConnectOperation <FBRequestDelegate> {
    BOOL finished;
}

- (BOOL) handleOpenURL: (NSURL*) url;

@end