


//
//  UIUtil.m
//  musubi
//
//  Created by Steve on 12-06-18.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IdentityUtils.h"
#import "MIdentity.h"
#import "Authorities.h"

@implementation IdentityUtils
+ (NSString*) internalSafeNameForIdentity:(MIdentity *)identity {
    if (identity == nil) {
        return nil;
    }
    
    if(identity.musubiName != nil) {
        return identity.musubiName;
    } else if(identity.name != nil) {
        return identity.name;
    } else if(identity.principal != nil) {
        return [self safePrincipalForIdentity:identity];
    } else {
        return nil;
    }
}

+ (NSString*) safePrincipalForIdentity:(MIdentity *)identity {
    //face book identities should pretty much always have an associated name
    //for us to use.  We consider the users name to be their identity at facebook
    //for the purposes of display.
    if(identity.type == kIdentityTypeFacebook && identity.name != nil) {
        return [NSString stringWithFormat:@"Facebook: %@", identity.name];
    }
    if(identity.principal != nil) {
        if(identity.type == kIdentityTypeEmail) 
            return identity.principal;
        if(identity.type == kIdentityTypeFacebook) 
            return [NSString stringWithFormat:@"Facebook #%@", identity.principal];
        return identity.principal;
    }
    if(identity.type == kIdentityTypeEmail) {
        return @"Email User";
    }
    if(identity.type == kIdentityTypeFacebook) {
        return @"Facebook User";
    }
    //we prefer not to say <unknown> anywhere, so principal will be blank
    //in cases where it would be displayed on the screen and we don't
    //have anything reasonable to display
    return @"";
}
@end
