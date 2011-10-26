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
//  PersistancyController.m
//  musubi
//
//  Created by Willem Bult on 10/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "PersistancyController.h"

@implementation PersistancyController 
@synthesize moc;

- (id) init {
    self = [super init];
    if (self != nil) {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
        NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        
        NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
        context = [[NSManagedObjectContext alloc] init];
        [context setPersistentStoreCoordinator: coordinator];
    }
    
    return self;
}

- (NSArray *)objsForFeed:(Feed *)f {
    
}

- (void)storeObj:(Obj *)o inFeed:(Feed *)f {
    
}


- (NSArray *)feeds {
    
}

- (ManagedFeed*) storeFeed:(Feed *)feed {
    NSManagedObject *newFeed = [NSEntityDescription
                                insertNewObjectForEntityForName:@"Feed"
                                inManagedObjectContext:context];
    
    [newFeed setValue:[feed session] forKey:@"session"];
    [newFeed setValue:[feed name] forKey:@"name"];
    [newFeed setValue:[feed key] forKey:@"key"];
}

@end
