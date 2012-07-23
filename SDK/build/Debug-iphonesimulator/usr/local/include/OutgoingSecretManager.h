//
//  OutgoingSecretManager.h
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EntityManager.h"

@class MOutgoingSecret, MIdentity;

@interface OutgoingSecretManager : EntityManager {
}

- (id) initWithStore: (PersistentModelStore*) s;
- (MOutgoingSecret*) outgoingSecretFrom: (MIdentity*) from to: (MIdentity*) to myTemporalFrame: (uint64_t) tfMe theirTemporalFrame: (uint64_t) tfThem;

@end
