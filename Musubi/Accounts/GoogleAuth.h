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
//  GoogleAuth.h
//  musubi
//
//  Created by Willem Bult on 3/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AphidIdentityProvider.h"

#define kGoogleOAuthScope @"xxx"
#define kGoogleClientId @"xxx"
#define kGoogleClientSecret @"xxx"
#define kGoogleKeyChainItemName @"xxx"

@class MAccount, AccountAuthManager, SettingsViewController, GTMOAuth2Authentication;

@interface GoogleAuthManager : NSObject {
}

- (void) didLoginWith: (GTMOAuth2Authentication*) auth;
- (GTMOAuth2Authentication*) activeAuth;
- (NSString*) activeAccessToken;

@end

// Abstract Facebook operation
@interface GoogleOAuthOperation : NSOperation {
    AccountAuthManager* manager;
    GoogleAuthManager* googleMgr;
    
    GoogleOAuthOperation* me;
}

@property (nonatomic) AccountAuthManager* manager;
@property (nonatomic) GoogleAuthManager* googleMgr;

- (id) initWithManager: (AccountAuthManager*) m;

@end

@interface GoogleOAuthCheckValidOperation : GoogleOAuthOperation

@end

@interface GoogleOAuthLoginOperation : GoogleOAuthOperation<NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
}

@end

@interface GoogleAphidAuthProvider : NSObject<AphidAuthProvider>
@end