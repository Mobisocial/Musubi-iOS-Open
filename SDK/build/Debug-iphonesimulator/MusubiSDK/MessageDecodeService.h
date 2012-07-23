//
//  MessageDecodeService.h
//  Musubi
//
//  Created by Willem Bult on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "IdentityProvider.h"
#import "ObjectPipelineService.h"

@class PersistentModelStoreFactory, PersistentModelStore;
@class FeedManager, MusubiDeviceManager, TransportManager, AccountManager, AppManager, IdentityManager;
@class MessageDecoder;

@interface MessageDecodeService : ObjectPipelineService

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) sf andIdentityProvider: (id<IdentityProvider>) ip;

@property (nonatomic, retain) id<IdentityProvider> identityProvider;

@end


@interface MessageDecodeOperation : ObjectPipelineOperation {
    // ManagedObject is not thread-safe, ObjectID is
    NSMutableArray* _dirtyFeeds;
}

@property (nonatomic) NSMutableArray* dirtyFeeds;
@property (nonatomic, assign) BOOL shouldRunProfilePush;

@property (nonatomic) MessageDecoder* decoder;
@property (nonatomic) MusubiDeviceManager* deviceManager;
@property (nonatomic) IdentityManager* identityManager;
@property (nonatomic) TransportManager* transportManager;
@property (nonatomic) FeedManager* feedManager;
@property (nonatomic) AccountManager* accountManager;
@property (nonatomic) AppManager* appManager;

+ (int) operationCount;

@end