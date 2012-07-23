//
//  MusubiDeviceManager.h
//  Musubi
//
//  Created by Willem Bult on 3/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EntityManager.h"

@class MDevice, MIdentity;

@interface MusubiDeviceManager : EntityManager {
}

- (id) initWithStore: (PersistentModelStore*) s;
- (uint64_t) localDeviceName;
- (MDevice*) deviceForName: (uint64_t) name andIdentity: (MIdentity*) mId;

@end
