//
//  FeedManager.h
//  Musubi
//
//  Created by Willem Bult on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EntityManager.h"

@class PersistentModelStore, MFeed, MApp, MIdentity, MObj;
@class Obj;

@interface FeedManager : EntityManager {
}

- (id) initWithStore: (PersistentModelStore*) s;

- (MFeed*) createExpandingFeedWithParticipants: (NSArray*) participants;
- (MFeed*) createOneTimeUseFeedWithParticipants: (NSArray*) participants;

- (void) deleteFeedAndMembers: (MFeed*) feed;
- (void) deleteFeedAndMembersAndObjs:(MFeed *)feed;

- (MFeed*) global;

- (MFeed *)feedWithType:(int16_t)type andCapability:(NSData *)capability;
- (NSArray*) displayFeeds;
- (NSArray*) unacceptedFeedsFromIdentity: (MIdentity*) ident;
- (NSArray*) acceptedFeedsFromIdentity: (MIdentity*) ident;

- (MIdentity*) ownedIdentityForFeed: (MFeed*) feed;
- (int) countIdentitiesFrom: (NSArray*) participants inFeed: (MFeed*) feed;
- (NSArray *)identitiesInFeed: (MFeed*) feed;
- (NSString*) identityStringForFeed: (MFeed*) feed;
- (BOOL) attachMember: (MIdentity*) mId toFeed: (MFeed*) feed;
- (void) attachMembers: (NSArray*) participants toFeed: (MFeed*) feed;
- (void) attachApp: (MApp*) app toFeed: (MFeed*) feed;
- (BOOL) app: (MApp*) app isAllowedInFeed:(MFeed*) feed;

- (void) acceptFeedsFromIdentity: (MIdentity*) ident;


+ (NSData*) fixedIdentifierForIdentities: (NSArray*) identities;
+ (BOOL) hasOwnedIdentity: (NSArray*) participants;
+ (NSURL*) uriForFeed: (MFeed*) feed;


@end
