//
//  FacebookAuth.h
//  Musubi
//
//  Created by Willem Bult on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Facebook.h"

#define kFacebookAppId @"291931937498365"

@class MAccount, AccountAuthManager, SettingsViewController;

@interface FacebookAuthManager : NSObject<FBSessionDelegate> 

@property (nonatomic, strong) Facebook* facebook;

- (id) initWithDelegate: (id<FBSessionDelegate>) d;
- (void) fbDidLogin;

- (NSString*) activeAccessToken;

@end

// Abstract Facebook operation
@interface FacebookConnectOperation : NSOperation<FBSessionDelegate> {
    //these are here so the ivars are public so there are less self.'s
    AccountAuthManager* manager;
    FacebookAuthManager* facebookMgr;
    
    FacebookConnectOperation* me;
}

@property (nonatomic, strong) AccountAuthManager* manager;
@property (nonatomic, strong) FacebookAuthManager* facebookMgr;

- (id) initWithManager: (AccountAuthManager*) m;

@end


// Operation to check the facebook auth token validity
@interface FacebookCheckValidOperation : FacebookConnectOperation <FBRequestDelegate>
@property (nonatomic, strong) FBRequest* request;
@end

// Operation to create a new account by connecting to FB
@interface FacebookLoginOperation : FacebookConnectOperation <FBRequestDelegate> {
    BOOL finished;
}
@property (nonatomic, strong) FBRequest* request;

- (BOOL) handleOpenURL: (NSURL*) url;

@end