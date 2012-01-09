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
    return [ManagedFeed withSession:session inContext:context];
}

- (ManagedFeed*) storeFeed:(Feed *) feed {
    return [ManagedFeed createOrSave:feed inContext:context];
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
