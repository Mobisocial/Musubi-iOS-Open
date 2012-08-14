//
//  IdentityManager.h
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EntityManager.h"

#define kIBEncryptionUserKeyRefreshSeconds 2592000 //30 * 24 * 60 * 60

@class IBEncryptionIdentity, MIdentity;

@interface IdentityManager : EntityManager

- (id) initWithStore: (PersistentModelStore*) s;

- (void) updateIdentity: (MIdentity*) ident;
- (void) createIdentity:(MIdentity *)ident;

- (NSArray*) ownedIdentities;
- (MIdentity*) defaultIdentity;
- (MIdentity*) defaultIdentityForParticipants: (NSArray*) participants;
- (MIdentity*) identityForIBEncryptionIdentity: (IBEncryptionIdentity*) ident;
- (MIdentity*) ensureIdentity: (IBEncryptionIdentity*) ibeId withName: (NSString*) name identityAdded: (BOOL*) identityAdded profileDataChanged: (BOOL*) profileDataChanged;
- (IBEncryptionIdentity *) ibEncryptionIdentityForHasedIdentity: (IBEncryptionIdentity*) ident;
- (IBEncryptionIdentity*) ibEncryptionIdentityForIdentity: (MIdentity*) ident forTemporalFrame: (uint64_t) tf;
- (uint64_t) computeTemporalFrameFromHash: (NSData*) hash;
- (uint64_t) computeTemporalFrameFromPrincipal: (NSString*) principal;
- (void) incrementSequenceNumberTo:(MIdentity *)to;
- (NSArray*) whitelistedIdentities;
- (NSArray*) claimedIdentities;
- (NSArray*) identitiesWithSentEqual0;

+ (NSString*) displayNameForIdentity: (MIdentity*)ident;
- (void) deleteIdentity:(MIdentity *) ident;

@end
