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
#import "ObjManager.h"

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
            @throw [NSException exceptionWithName:@"No owned identity" reason:@"Feed has no owned identity" userInfo:nil];
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

- (void) attachMembers: (NSArray*) participants toFeed: (MFeed*) feed {
    for (MIdentity* mId in participants) {
        MFeedMember* fm = (MFeedMember*)[store createEntity:@"FeedMember"];
        [fm setFeed: feed];
        [fm setIdentity: mId];
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

- (MObj*)sendObj:(Obj *)obj toFeed:(MFeed *)feed fromApp: (MApp*) app {

    if (![self app: app isAllowedInFeed: feed]) {
        @throw [NSException exceptionWithName:@"NotAllowed" reason:@"App not allowed in feed" userInfo:nil];
    }

    MIdentity* ownedId = [self ownedIdentityForFeed: feed];
    if (ownedId == nil) {
        @throw [NSException exceptionWithName:@"No Owned" reason:@"No owned identity for feed" userInfo: nil];
    }

    DeviceManager* devManager = [[DeviceManager alloc] initWithStore: store];
    MDevice* device = [devManager deviceForName:[devManager localDeviceName] andIdentity:ownedId];
    
    SBJsonWriter* writer = [[[SBJsonWriter alloc] init] autorelease];
    NSString* json = [writer stringWithObject:obj.data];
    if (json.length > 480*1024)
        @throw [NSException exceptionWithName:@"Too large" reason:@"JSON is too large to send" userInfo:nil];
    
    if (obj.raw.length > 480*1024)
        @throw [NSException exceptionWithName:@"Too large" reason:@"Raw is too large to send" userInfo:nil];
    
    
    MObj* mObj = (MObj*)[store createEntity:@"Obj"];
    [mObj setType: obj.type];
    [mObj setJson: json];
    [mObj setRaw: obj.raw];
    [mObj setFeed: feed];
    [mObj setApp: app];
    [mObj setIdentity: ownedId];
    [mObj setDevice: device];
    [mObj setTimestamp: [[NSDate date] timeIntervalSinceReferenceDate]];
    [mObj setLastModified: mObj.timestamp];
    [mObj setProcessed: NO];
    [mObj setRenderable: NO];
    
    [store save];
    
    return mObj;
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
