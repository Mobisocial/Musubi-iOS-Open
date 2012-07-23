//
//  GoogleAuth.h
//  musubi
//
//  Created by Willem Bult on 3/30/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

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