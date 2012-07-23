//
//  ProfileObj.h
//  musubi
//
//  Created by T.J. Purtell on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Obj.h"
#import "MIdentity.h"

#define kObjTypeProfile @"profile"

@class PersistentModelStore;
@interface ProfileObj : Obj

- (id) initWithUser: (MIdentity*)user replyRequested:(BOOL)replyRequested includePrincipal:(BOOL)includePrincipal;
- (id) initRequest;

+ (void)handleFromSender:(MIdentity*)sender profileJson:(NSString*)json profileRaw:(NSData*)raw withStore:(PersistentModelStore*)store;
+(void)sendAllProfilesWithStore:(PersistentModelStore*)store;
+(void)sendProfilesTo:(NSArray*)people replyRequested:(BOOL)replyRequested withStore:(PersistentModelStore*)store;

@end
