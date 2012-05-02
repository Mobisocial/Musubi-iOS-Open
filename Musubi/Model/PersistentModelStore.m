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
#import "Musubi.h"

@implementation PersistentModelStoreFactory

@synthesize coordinator;

+ (NSURL*) pathForStoreWithName: (NSString*) name {
    NSArray *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    return [NSURL fileURLWithPath: [[documentsPath objectAtIndex:0] 
                                    stringByAppendingPathComponent: [NSString stringWithFormat: @"%@.sqlite", name]]];
}

+ (void) deleteStoreWithName: (NSString*) name {
    NSURL* storePath = [PersistentModelStoreFactory pathForStoreWithName:name];
    [[NSFileManager defaultManager] removeItemAtPath:storePath.path error:NULL];
}

- (id) initWithName: (NSString*) name {
    NSURL *path = [PersistentModelStoreFactory pathForStoreWithName:name];
    return [self initWithPath: path];
}

- (id) initWithPath: (NSURL*) path {
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    NSError *error = nil;
    NSPersistentStoreCoordinator *c = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    [c addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:path options:nil error:&error];
    
    return [self initWithCoordinator:c];
}

- (id)initWithCoordinator:(NSPersistentStoreCoordinator *)c {
    self = [super init];
    if (self)
        return nil;
    
    self.coordinator = c;
    return self;
}

- (PersistentModelStore *) newStore {
    return [[PersistentModelStore alloc] initWithCoordinator: coordinator];
}

@end

@implementation PersistentModelStore

@synthesize context;

- (id) initWithCoordinator: (NSPersistentStoreCoordinator*) coordinator {
    self = [super init];
    if (!self)
        return nil;
//TODO: ahould we be doing this instead?
//    NSManagedObjectContext* moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
//    moc.parentContext = root CONTEXT;
    
    self.context = [[NSManagedObjectContext alloc] init];
    context.persistentStoreCoordinator = coordinator;
            
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(otherContextSaved:) name:NSManagedObjectContextDidSaveNotification object:nil];
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:nil];
}

- (void) otherContextSaved: (NSNotification*) notification {
    if (notification.object != context) {
        [context mergeChangesFromContextDidSaveNotification:notification];
    }
}

- (NSArray *)query:(NSPredicate *)predicate onEntity:(NSString *)entityName {
    return [self query:predicate onEntity:entityName sortBy:nil];
}

- (NSArray*) query: (NSPredicate*) predicate onEntity: (NSString*) entityName sortBy:(NSSortDescriptor *)sortDescriptor{
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setPredicate:predicate];
    if (sortDescriptor)
        [request setSortDescriptors: [NSArray arrayWithObject: sortDescriptor]];
    
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
        @throw [NSException exceptionWithName:kMusubiExceptionUnexpected reason:[NSString stringWithFormat:@"Unexpected error occurred: %@", err] userInfo:nil];
    }
}
- (void)reset {
    [context reset];
}

@end
