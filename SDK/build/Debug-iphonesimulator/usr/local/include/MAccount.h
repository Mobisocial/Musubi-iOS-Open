//
//  MAccount.h
//  musubi
//
//  Created by MokaFive User on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MFeed, MIdentity;
#define kAccountNameProvisionalWhitelist @"provisional_whitelist"
#define kAccountNameLocalWhitelist @"local_whitelist"

#define kAccountTypeInternal @"mobisocial.musubi.internal"
#define kAccountTypeFacebook @"com.facebook.auth.login"
#define kAccountTypeGoogle @"com.google"
#define kAccountTypeEmail @"mobisocial.musubi.email"


@interface MAccount : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) MFeed *feed;
@property (nonatomic, retain) MIdentity *identity;

@end
