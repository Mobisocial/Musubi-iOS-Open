//
//  PersistentModelStore.h
//  Musubi
//
//  Created by Willem Bult on 2/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface PersistentModelStore : NSObject {
    NSManagedObjectContext* context;
    NSMutableArray* createdObjects;
}

@property (nonatomic, strong) NSManagedObjectContext* context;
@property (nonatomic, strong) NSMutableArray* createdObjects;

- (id) initWithCoordinator: (NSPersistentStoreCoordinator*) coordinator;
- (id) initWithParent: (PersistentModelStore*)parent;

- (BOOL) isDeletedObject: (NSManagedObject*) object;

- (NSArray*) query: (NSPredicate*) predicate onEntity: (NSString*) entityName;
- (NSArray*) query: (NSPredicate*) predicate onEntity: (NSString*) entityName sortBy:(NSSortDescriptor *)sortDescriptor;
- (NSArray*) query: (NSPredicate*) predicate onEntity: (NSString*) entityName sortBy:(NSSortDescriptor *)sortDescriptor limit:(NSInteger)limit;
- (NSManagedObject*) queryFirst: (NSPredicate*) predicate onEntity: (NSString*) entityName;
- (NSManagedObject *)createEntity: (NSString*) entityName;

- (void) save;

@end

@interface PersistentModelStoreFactory : NSObject {
    NSPersistentStoreCoordinator* coordinator;
    PersistentModelStore* rootStore;
}

@property (nonatomic, strong) NSPersistentStoreCoordinator* coordinator;
@property (nonatomic, strong, readonly) PersistentModelStore* rootStore;

+ (PersistentModelStoreFactory *)sharedInstance;
+ (NSURL*) pathForStoreWithName: (NSString*) name;
+ (void) deleteStoreWithName: (NSString*) name;
+ (void) restoreStoreFromFile: (NSURL*) path;

- (id) initWithCoordinator: (NSPersistentStoreCoordinator*) coordinator;
- (id) initWithPath: (NSURL*) path;
- (id) initWithName: (NSString*) name;

- (PersistentModelStore*) newStore;

@end
