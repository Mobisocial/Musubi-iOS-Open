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
//  ObjectStore.m
//  musubi
//
//  Created by Willem Bult on 10/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ObjectStore.h"

@implementation ObjectStore 

static ObjectStore* _sharedInstance = nil;

@synthesize context;

+(id)alloc
{
	@synchronized([ObjectStore class])
	{
		NSAssert(_sharedInstance == nil, @"Attempted to allocate a second instance of a singleton.");
		_sharedInstance = [super alloc];
		return _sharedInstance;
	}
    
	return nil;
}

- (id) init {
    self = [super init];
    if (self != nil) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
        NSManagedObjectModel *mom = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] autorelease];
        
        NSArray *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
        NSURL *storeUrl = [NSURL fileURLWithPath: [[documentsPath objectAtIndex:0] 
                                                   stringByAppendingPathComponent: @"Model.sqlite"]];
        
        NSError *error = nil;
        NSPersistentStoreCoordinator *coordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom] autorelease];
        [coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error];

        if (error != nil) {
            NSLog(@"Could not create data store: %@", error);
            return nil;
        }
        
        
        context = [[NSManagedObjectContext alloc] init];
        [context setPersistentStoreCoordinator: coordinator];
    }
    
    return self;
}

- (NSArray *) feeds {
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:context];

    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entity];

    NSError *error = nil;
    return [context executeFetchRequest:request error:&error];
}


- (ManagedFeed*) feedForSession: (NSString *) session {
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Feed" inManagedObjectContext:context];
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entity];
    [request setPredicate:[NSPredicate predicateWithFormat:@"session = %@", session]];
    
    NSError *error = nil;
    NSArray* results = [context executeFetchRequest:request error:&error];
    if (results != nil && [results count] > 0) {
        return [results objectAtIndex:0];
    }
    
    return nil;
}

- (ManagedFeed*) storeFeed:(Feed *) feed {
    ManagedFeed *newFeed = [NSEntityDescription
                                insertNewObjectForEntityForName:@"Feed"
                                inManagedObjectContext:context];
    
    [newFeed setValue:[feed session] forKey:@"session"];
    [newFeed setValue:[feed name] forKey:@"name"];
    [newFeed setValue:[feed key] forKey:@"key"];
    [newFeed setValue:[[feed feedUri] description] forKey:@"url"];
    
    for (User* member in [feed members]) {
        ManagedUser* user = [self userWithPublicKey:[[member id] decodeBase64]];
        if (user == nil) {
            user = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:context];
            [user setName: [member name]];
            [user setPublicKey: [[member id] decodeBase64]];
            if ([member picture] != nil) {
                [user setPicture: UIImageJPEGRepresentation([member picture], 0.95)];
            }
        }
        
        NSManagedObject* managedMember =[NSEntityDescription insertNewObjectForEntityForName:@"FeedMember" inManagedObjectContext:context];
        [managedMember setValue:newFeed forKey:@"feed"];
        [managedMember setValue:user forKey:@"user"];
    }
    
    [context save:NULL];
    return newFeed;
}

- (NSArray *) users {
    return [ManagedUser allInContext: context];
}

- (ManagedUser *) userWithPublicKey: (NSData*) publicKey {    
    return [ManagedUser withPublicKey: publicKey inContext: context];
}

+ (ObjectStore*) sharedInstance
{
	@synchronized([ObjectStore class])
	{
		if (!_sharedInstance)
			[[self alloc] init];
        
		return _sharedInstance;
	}
    
	return nil;
}



@end
