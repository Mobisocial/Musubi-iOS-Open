//
//  EntityManager.h
//  Musubi
//
//  Created by Willem Bult on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PersistentModelStore;

@interface EntityManager : NSObject{
    PersistentModelStore* store;
    NSString* entityName;
}

@property (nonatomic) NSString* entityName;
@property (nonatomic) PersistentModelStore* store;

- (id) initWithEntityName: (NSString*) name andStore: (PersistentModelStore*) s;
- (id) create;
- (NSArray*) query:(NSPredicate*) predicate;
- (NSArray *)query:(NSPredicate *)predicate sortBy:(NSSortDescriptor*) sortDescriptor;
- (NSArray *)query:(NSPredicate *)predicate sortBy:(NSSortDescriptor*) sortDescriptor limit:(NSInteger) limit;
- (NSManagedObject*) queryFirst: (NSPredicate*) predicate;

@end
