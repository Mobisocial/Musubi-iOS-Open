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
//  ObjectStore.h
//  musubi
//
//  Created by Willem Bult on 10/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ManagedFeed.h"
#import "ManagedMessage.h"
#import "ManagedUser.h"
#import "Group.h"
#import "Message.h"
#import "Obj.h"

@interface ObjectStore : NSObject {
    NSManagedObjectContext* context;
}

@property (nonatomic,retain) NSManagedObjectContext* context;

- (ManagedMessage*) storeMessage: (Message*) msg forFeed: (ManagedFeed*) feed;

- (NSArray*) feeds;
- (ManagedFeed*) feedForSession: (NSString*) session;
- (ManagedFeed*) storeFeed: (Group*) feed;
- (NSArray*) messagesForFeed: (ManagedFeed*) feed;

- (NSArray*) users;
- (ManagedUser *) userWithPublicKey: (NSData*) publicKey;

+ (ObjectStore*) sharedInstance;

@end
