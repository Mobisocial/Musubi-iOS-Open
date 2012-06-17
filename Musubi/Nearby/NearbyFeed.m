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
//  NearbyFeed.h
//  Extracts or holds the fields needed for sharing a feed by geolocation 
//
//  Created by T.J. Purtell on 6/17/12.
//  Copyright (c) 2012 Stanford MobiSocial Labratory. All rights reserved.
//

#import "NearbyFeed.h"
#import <CoreData/CoreData.h>
#import "MFeed.h"
#import "MIdentity.h"
#import "IdentityManager.h"
#import "Authorities.h"
#import "FeedManager.h"
#import "PersistentModelStore.h"

@implementation NearbyFeed
@synthesize groupCapability, groupName, thumbnail, sharerHash, sharerName, sharerType, memberCount;

-(id)init 
{
    self = [super init];
    return self;
}

- (id)initWithFeedId:(NSManagedObjectID*)feedId andStore:(PersistentModelStore*)store
{
    self = [super init];
    if(!self)
        return nil;
    
    FeedManager* fm = [[FeedManager alloc] initWithStore:store];
    NSError* error;
    MFeed* feed = (MFeed*)[store.context existingObjectWithID:feedId error:&error];
    NSAssert(feed.type == kFeedTypeExpanding, @"feed must be expanding");
    if(!feed) {
        NSLog(@"failed to look up feed for broadcast,.. obj id = %@", feedId);
        @throw error;
    }
        
    groupCapability = feed.capability;
    groupName = [fm identityStringForFeed:feed];
    memberCount = [fm identitiesInFeed:feed].count;
    
    IdentityManager* im = [[IdentityManager alloc] initWithStore:store];
    NSArray* mine = [im ownedIdentities];
    MIdentity* sharer = nil;
    for(MIdentity* me in mine) {
        if(me.type != kIdentityTypeLocal) {
            sharer = me;
            break;
        }
    }
    NSAssert(sharer, @"A non-local identity must already be bound");
    sharerType = sharer.type;
    sharerHash = sharer.principalHash;
    sharerName = sharer.musubiName;
    if(!sharerName)
        sharerName = sharer.name;
    if(!sharerName)
        sharerName = sharer.principal;
    if(!sharerName)
        sharerName = @"Unknown";
    
    return self;
}

@end
