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
//  ManagedUser.m
//  musubi
//
//  Created by Willem Bult on 11/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ManagedUser.h"

@implementation ManagedUser

@dynamic name;
@dynamic publicKey;
@dynamic picture;

- (User *)user {
    User* user = [[User alloc] init];
    [user setName: [self name]];
    [user setId: [[self publicKey] encodeBase64]];
    [user setPicture: [UIImage imageWithData: [self picture]]];
    
    return user;
}

+ (NSArray *) allInContext: (NSManagedObjectContext*) context {
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:context];
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entity];
    
    NSError *error = nil;
    return [context executeFetchRequest:request error:&error];
}

+ (id)withPublicKey:(NSData *)publicKey inContext:(NSManagedObjectContext *)context{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:context];
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entity];
    [request setPredicate:[NSPredicate predicateWithFormat:@"publicKey = %@", publicKey]];
    
    NSError *error = nil;
    NSArray* results = [context executeFetchRequest:request error:&error];
    if (results != nil && [results count] > 0) {
        return [results objectAtIndex:0];
    }
    
    return nil;
}


@end
