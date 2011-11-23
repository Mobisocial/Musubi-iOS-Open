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
//  Persistancy.m
//  musubi
//
//  Created by Willem Bult on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ManagedFeed.h"


@implementation ManagedFeed

@dynamic key;
@dynamic name;
@dynamic session;
@dynamic url;
@dynamic messages;

- (ManagedMessage*) storeMessage: (SignedMessage*) msg{
    
    NSData* contents = [NSPropertyListSerialization dataFromPropertyList: [[msg obj] data]
                                                                  format: NSPropertyListBinaryFormat_v1_0
                                                        errorDescription: nil];
    
    ManagedMessage *newMessage = [NSEntityDescription
                                  insertNewObjectForEntityForName:@"Message"
                                  inManagedObjectContext:[self managedObjectContext]];
    
    [newMessage setContents: contents];
    [newMessage setApp: [msg appId]];
    [newMessage setTimestamp: [msg timestamp]];
    [newMessage setFeed: self];
    [newMessage setType: [[msg obj] type]];
    [newMessage setSender:[self userWithId: [[msg sender] id]]];
    [newMessage setId: [msg hash]];
    [newMessage setParent: [(SignedMessage*)[msg parent] hash]];
    
    [[self managedObjectContext] save:NULL];
    return newMessage;
}

- (NSArray *) allMessages {
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Message" inManagedObjectContext:[self managedObjectContext]];
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entity];
    [request setPredicate: [NSPredicate predicateWithFormat:@"feed = %@", self]];
    
    NSError *error = nil;
    return [[self managedObjectContext] executeFetchRequest:request error:&error];
}

- (NSArray *) allMembers {
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"FeedMember" inManagedObjectContext:[self managedObjectContext]];
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entity];
    [request setPredicate: [NSPredicate predicateWithFormat:@"feed = %@", self]];
    
    NSError *error = nil;
    NSArray* members= [[self managedObjectContext] executeFetchRequest:request error:&error];
    
    NSMutableArray* users = [NSMutableArray array];
    for (NSManagedObject* member in members) {
        [users addObject:[member valueForKey:@"user"]];
    }
    
    return users;
}

- (ManagedUser *) userWithId: (NSString*) id {
    return [ManagedUser withPublicKey:[id decodeBase64] inContext:[self managedObjectContext]];
}


@end
