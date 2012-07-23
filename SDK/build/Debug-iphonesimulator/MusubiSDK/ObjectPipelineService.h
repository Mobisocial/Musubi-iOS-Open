//
//  ObjectPipelineService.h
//  musubi
//
//  Created by Willem Bult on 6/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PersistentModelStore, PersistentModelStoreFactory;



@interface ObjectPipelineServiceConfiguration : NSObject

typedef int(^QueueSelector)(NSManagedObject* obj);

@property (nonatomic, strong) NSString* model;
@property (nonatomic, strong) NSPredicate* selector;
@property (nonatomic, strong) NSString* notificationName;
@property (nonatomic, strong) Class operationClass;
@property (nonatomic, assign) int numberOfQueues;
@property (nonatomic, strong) QueueSelector queueSelector; 

@end

@interface ObjectPipelineService : NSObject

@property (nonatomic, retain) PersistentModelStoreFactory* storeFactory;
@property (nonatomic, strong) ObjectPipelineServiceConfiguration* config;
@property (nonatomic, strong) NSMutableArray* pending;
@property (nonatomic, strong) NSMutableArray* queues;
@property (nonatomic, strong) NSLock* pendingLock;

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) sf andConfiguration: (ObjectPipelineServiceConfiguration*) config;
- (void) start;
- (void) stop;
- (BOOL) isFinished;

@end

@interface ObjectPipelineOperation : NSOperation

@property (nonatomic, retain) NSManagedObjectID* objId;
@property (nonatomic, retain) ObjectPipelineService* service;
@property (nonatomic, retain) PersistentModelStore* store;
@property (nonatomic, assign) BOOL retry;

- (id) initWithObjectId: (NSManagedObjectID*) objId andService: (ObjectPipelineService*) service;
- (BOOL)performOperationOnObject: (NSManagedObject*) object;
- (void) log:(NSString*) format, ...;
@end