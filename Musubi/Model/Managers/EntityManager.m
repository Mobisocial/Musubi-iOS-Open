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
//  EntityManager.m
//  Musubi
//
//  Created by Willem Bult on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EntityManager.h"

@implementation EntityManager

@synthesize entityName, store;

- (id)initWithEntityName:(NSString *)name andStore:(PersistentModelStore *)s {
    self = [super init];
    if (self != nil) {
        [self setEntityName: name];
        [self setStore: s];
    }
    return self;
}

- (NSArray*) query: (NSPredicate*) predicate {
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:[store context]];
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entity];
    [request setPredicate:predicate];
    
    NSLog(@"Query: %@", request);
    
    NSError *error = nil;
    return [[store context] executeFetchRequest:request error:&error];
}

- (NSManagedObject*) queryFirst: (NSPredicate*) predicate {
    NSArray* results = [self query:predicate];
    if (results.count > 0) {
        return [results objectAtIndex:0];
    } else {
        return nil;
    }
}

- (NSManagedObject *)create {
    NSManagedObject* entity = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext: [store context]];
    return entity;
}

@end
