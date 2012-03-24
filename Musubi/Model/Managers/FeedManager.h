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
- (void) attachMember: (MIdentity*) mId toFeed: (MFeed*) feed;
- (void) attachMembers: (NSArray*) participants toFeed: (MFeed*) feed;
- (void) attachApp: (MApp*) app toFeed: (MFeed*) feed;
- (int) countIdentitiesFrom: (NSArray*) participants inFeed: (MFeed*) feed;

- (MObj*) sendObj:(Obj *)obj toFeed:(MFeed *)feed fromApp: (MApp*) app;

- (BOOL) app: (MApp*) app isAllowedInFeed:(MFeed*) feed;
- (MIdentity*) ownedIdentityForFeed: (MFeed*) feed;
- (NSArray *)identitiesInFeed: (MFeed*) feed;

- (MFeed*) global;
- (MFeed*) feedWithType:(uint16_t)type andCapability:(NSData *)capability;

+ (NSData*) fixedIdentifierForIdentities: (NSArray*) identities;
+ (BOOL) hasOwnedIdentity: (NSArray*) participants;
+ (NSURL*) uriForFeed: (MFeed*) feed;


@end
