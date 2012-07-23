//
//  MessageEncodeService.h
//  Musubi
//
//  Created by Willem Bult on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "IdentityProvider.h"
#import "ObjectPipelineService.h"

@interface MessageEncodeService : ObjectPipelineService

@property (nonatomic, strong) id<IdentityProvider> identityProvider;

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) sf andIdentityProvider: (id<IdentityProvider>) ip;

@end

@interface MessageEncodeOperation : ObjectPipelineOperation
@end
