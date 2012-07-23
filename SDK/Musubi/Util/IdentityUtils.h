


//
//  IdentityUtil.h
//  musubi
//
//  Created by Steve on 12-06-18.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MIdentity;

@interface IdentityUtils : NSObject
+ (NSString*) internalSafeNameForIdentity:(MIdentity*) identity;
+ (NSString*) safePrincipalForIdentity:(MIdentity*) identity;
@end
