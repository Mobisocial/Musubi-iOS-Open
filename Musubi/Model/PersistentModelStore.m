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
//  PersistentModelStore.m
//  Musubi
//
//  Created by Willem Bult on 2/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PersistentModelStore.h"

@implementation PersistentModelStore

@synthesize context;

+ (NSURL*) pathForStoreWithName: (NSString*) name {
    NSArray *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    return [NSURL fileURLWithPath: [[documentsPath objectAtIndex:0] 
                                    stringByAppendingPathComponent: [NSString stringWithFormat: @"%@.sqlite", name]]];
}

+ (NSPersistentStoreCoordinator*) coordinatorWithName: (NSString*) name {
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    NSManagedObjectModel *mom = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] autorelease];
    
    NSError *error = nil;
    NSURL *path = [PersistentModelStore pathForStoreWithName:name];
    NSPersistentStoreCoordinator *coordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom] autorelease];
    [coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:path options:nil error:&error];
    
    if (error != nil) {
        NSLog(@"Could not create data store: %@", error);
        return nil;
    }
    
    return coordinator;
}

- (id) init {
    return [self initWithCoordinator:[PersistentModelStore coordinatorWithName:@"Model"]];
}

- (id) initWithCoordinator: (NSPersistentStoreCoordinator*) coordinator {
    self = [super init];
    if (self != nil) {
        context = [[NSManagedObjectContext alloc] init];
        [context setPersistentStoreCoordinator: coordinator];
    }
    
    return self;
}

- (NSArray*) query: (NSPredicate*) predicate onEntity: (NSString*) entityName {
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entity];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    return [context executeFetchRequest:request error:&error];
}

- (NSManagedObject*) queryFirst: (NSPredicate*) predicate onEntity: (NSString*) entityName {
    NSArray* results = [self query:predicate onEntity:entityName];
    if (results.count > 0) {
        return [results objectAtIndex:0];
    } else {
        return nil;
    }
}

- (NSManagedObject *)createEntity: (NSString*) entityName {
    NSManagedObject* entity = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext: context];
    return entity;
}

- (void)save {
    NSError* err = nil;
    [context save:&err];
    
    if (err != nil) {
        @throw err;
    }
}


- (MIdentity *)createIdentity {
    return [NSEntityDescription insertNewObjectForEntityForName:@"Identity" inManagedObjectContext: context];
}

- (MDevice *)createDevice {
    return [NSEntityDescription insertNewObjectForEntityForName:@"Device" inManagedObjectContext: context];
}

- (MEncodedMessage *)createEncodedMessage {
    return [NSEntityDescription insertNewObjectForEntityForName:@"EncodedMessage" inManagedObjectContext: context];
}

- (MIncomingSecret *)createIncomingSecret {
    return [NSEntityDescription insertNewObjectForEntityForName:@"IncomingSecret" inManagedObjectContext: context];
}

- (MOutgoingSecret *)createOutgoingSecret {
    return [NSEntityDescription insertNewObjectForEntityForName:@"OutgoingSecret" inManagedObjectContext: context];
}

- (NSArray*) unsentOutboundMessages {
    return [self query:[NSPredicate predicateWithFormat:@"processed=0 AND outbound=1"] onEntity:@"EncodedMessage"];
}

@end
