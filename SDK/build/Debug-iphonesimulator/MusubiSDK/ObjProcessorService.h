//
//  ObjPipelineService.h
//  musubi
//
//  Created by Willem Bult on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ObjectPipelineService.h"

@class PersistentModelStoreFactory, IdentityManager;

@interface ObjProcessorService : ObjectPipelineService

@property (atomic, strong) NSMutableArray* feedsToNotify;
@property (nonatomic, strong) NSMutableDictionary* pendingParentHashes;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)sf;

@end

@interface ObjProcessOperation : ObjectPipelineOperation

+ (int) operationCount;

@end