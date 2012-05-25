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
//  FeedManager.m
//  Musubi
//
//  Created by Willem Bult on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedManager.h"

#import "NSData+Crypto.h"

#import "Musubi.h"
#import "SBJSON.h"
#import "Obj.h"

#import "PersistentModelStore.h"
#import "ObjManager.h"
#import "IdentityManager.h"
#import "MusubiDeviceManager.h"
#import "IntroductionObj.h"

#import "MFeed.h"
#import "MFeedMember.h"
#import "MFeedApp.h"
#import "MDevice.h"
#import "MObj.h"
#import "MIdentity.h"

@implementation FeedManager

- (id)initWithStore:(PersistentModelStore *)s {
    self = [super initWithEntityName:@"Feed" andStore:s];
    if (self != nil) {
    }
    return self;
}

/**
 * Creates a new feed with expandable membership with the given membership. If the feed
 * does not have an owned identity, one is inserted automatically. If no owned identities
 * are available, an exception is thrown.
 */
- (MFeed*) createExpandingFeedWithParticipants: (NSArray*) participants {
    
    if (![FeedManager hasOwnedIdentity:participants]) {
        // Find a default owned identity to include in this feed
        IdentityManager* idManager = [[IdentityManager alloc] initWithStore:store];
        MIdentity* me = [idManager defaultIdentityForParticipants: participants];
        if (me == nil) {
            @throw [NSException exceptionWithName:kMusubiExceptionFeedWithoutOwnedIdentity reason:@"Feed has no owned identity" userInfo:nil];
        }
        
        NSMutableArray* newParticipants = [NSMutableArray arrayWithCapacity:participants.count + 1];
        [newParticipants addObject: me];
    
        for (MIdentity* mId in participants) {
            [newParticipants addObject:mId];
        }
    
        participants = newParticipants;
    }

    MFeed* feed = (MFeed*)[self create];
    [feed setType: kFeedTypeExpanding];
    [feed setCapability: [NSData generateSecureRandomKeyOf:32]];
    [feed setShortCapability: *(uint64_t *)feed.capability.bytes];
    [feed setAccepted: YES];
    
    [self attachMembers:participants toFeed:feed];
    return feed;
}

- (void)deleteFeedAndMembers:(MFeed *)feed {
    for (MFeedMember* member in [store query: [NSPredicate predicateWithFormat:@"feed = %@", feed] onEntity:@"FeedMember"]) {
        [store.context deleteObject:member];
    }
    
    [store.context deleteObject:feed];    
}

- (void)deleteFeedAndMembersAndObjs:(MFeed *)feed {
    for (MObj* obj in [store query:[NSPredicate predicateWithFormat:@"feed == %@", feed] onEntity:@"Obj"]) {
        [store.context deleteObject:obj];
    }
    
    for (MFeedMember* member in [store query: [NSPredicate predicateWithFormat:@"feed == %@", feed] onEntity:@"FeedMember"]) {
        [store.context deleteObject:member];
    }
    
    [store.context deleteObject:feed];    
    [store.context save:nil];
}


- (void) attachMember: (MIdentity*) mId toFeed: (MFeed*) feed {
    if ([store queryFirst:[NSPredicate predicateWithFormat:@"feed = %@ AND identity = %@", feed, mId] onEntity:@"FeedMember"] == nil) {
        MFeedMember* fm = (MFeedMember*)[store createEntity:@"FeedMember"];
        [fm setFeed: feed];
        [fm setIdentity: mId];
    }
}

- (void) attachMembers: (NSArray*) participants toFeed: (MFeed*) feed {
    for (MIdentity* mId in participants) {
        [self attachMember: mId toFeed: feed];
    }
}

- (void) attachApp: (MApp*) app toFeed: (MFeed*) feed {
    if ([store queryFirst:[NSPredicate predicateWithFormat:@"feed = %@ AND app = %@", feed, app] onEntity:@"FeedApp"] == nil) {
        MFeedApp* fa = (MFeedApp*)[store createEntity:@"FeedApp"];
        [fa setFeed: feed];
        [fa setApp: app];
    }
}

- (int) countIdentitiesFrom: (NSArray*) participants inFeed: (MFeed*) feed {
    
    NSArray* matching = [store query: [NSPredicate predicateWithFormat: @"(feed == %@) AND (identity in %@)", feed, participants] onEntity:@"FeedMember"];
    if (matching)
        return matching.count;
    else
        return 0;
}

- (BOOL)app:(MApp *)app isAllowedInFeed:(MFeed *)feed {
    return YES;
}

- (MIdentity *)ownedIdentityForFeed:(MFeed *)feed {
    MFeedMember* fm = (MFeedMember*)[store queryFirst: [NSPredicate predicateWithFormat:@"(feed == %@) and (identity.owned == 1)", feed] onEntity:@"FeedMember"];
    if (fm)
        return fm.identity;
    else
        return nil;
}

- (MFeed *)global {
    return (MFeed*)[self queryFirst: [NSPredicate predicateWithFormat:@"(type == %hd) AND (name == %@", kFeedTypeAsymmetric, kFeedNameGlobalWhitelist]];
}

- (MFeed *)feedWithType:(int16_t)type andCapability:(NSData *)capability {
    return (MFeed*)[self queryFirst: [NSPredicate predicateWithFormat:@"(type == %hd) AND (shortCapability == %llu)", type, *(uint64_t*)capability.bytes]];
}

- (NSArray *) displayFeeds {
    return [self query:[NSPredicate predicateWithFormat:@"(latestRenderableObjTime > 0) AND (accepted == 1)"] sortBy:[NSSortDescriptor sortDescriptorWithKey:@"latestRenderableObjTime" ascending:FALSE]];
}

- (NSArray *)identitiesInFeed: (MFeed*) feed {
    NSMutableArray* identities = [NSMutableArray array];
    for (MFeedMember* member in [store query:[NSPredicate predicateWithFormat:@"feed = %@", feed] onEntity:@"FeedMember"]) {
        [identities addObject:member.identity];
    }
    return identities;
}

- (NSString*) identityStringForFeed: (MFeed*) feed {
    NSMutableArray* otherParticipants = [NSMutableArray array];
    for (MIdentity* ident in [self identitiesInFeed:feed]) {
        if (!ident.owned) {
            if (ident.name)
                [otherParticipants addObject: ident.name];
            else if (ident.principal)
                [otherParticipants addObject: ident.principal];
            else
                [otherParticipants addObject: @"Unknown"];
        }
    }
    
    return [otherParticipants componentsJoinedByString:@", "];
}

- (NSArray*) unacceptedFeedsFromIdentity: (MIdentity*) ident {
    NSMutableArray* feeds = [NSMutableArray array];
    for (MFeedMember* mFeedMember in [store query:[NSPredicate predicateWithFormat:@"identity = %@", ident] onEntity:@"FeedMember"]) {
        [feeds addObject: mFeedMember.feed];
    }
    
    NSArray* unaccepted = [self query: [NSPredicate predicateWithFormat:@"(self IN %@) AND ((type == %d) OR (type == %d)) AND (accepted == NO)", feeds, kFeedTypeFixed, kFeedTypeExpanding]];
    return unaccepted;
}

- (void) acceptFeedsFromIdentity: (MIdentity*) ident {
    for (MFeed* feed in [self unacceptedFeedsFromIdentity:ident]) {
        int64_t now = [[NSDate date] timeIntervalSince1970] * 1000;

        [feed setAccepted: YES];
        [feed setLatestRenderableObjTime: now];
        [store save];
    }
}

+ (BOOL) hasOwnedIdentity: (NSArray*) participants {
    for (MIdentity* mId in participants) {
        if (mId.owned) {
            return true;
        }
    }
    return false;
}

+ (NSData*) fixedIdentifierForIdentities: (NSArray*) identities {
    NSComparisonResult (^comparator)(id ident1, id ident2) =  ^(id ident1, id ident2) {
        if (((MIdentity*) ident1).type < ((MIdentity*) ident2).type) {
            return -1;
        } else if (((MIdentity*) ident1).type > ((MIdentity*) ident2).type) {
            return 1;
        } else {
            return [[[((MIdentity*) ident1) principalHash] hex] compare:[[((MIdentity*) ident2) principalHash] hex]];
        }
    };
    
    uint16_t lastType = 0;
    NSData* lastHash = [NSData data];
    NSMutableData* hashData = [NSMutableData data];
    for (MIdentity* ident in [identities sortedArrayUsingComparator:comparator]) {
        uint8_t type = ident.type;
        NSData* hash = ident.principalHash;
        
        if (type == lastType && [hash isEqualToData:lastHash])
            continue;
        
        [hashData appendBytes:&type length:1];
        [hashData appendData:hash];
    }
    
    return [hashData sha256Digest];
}

+ (NSURL*) uriForFeed: (MFeed*) feed {
    return [NSURL URLWithString:[NSString stringWithFormat:@"content://org.musubi.db/feeds/%d", feed.objectID.hash]];
}



@end
