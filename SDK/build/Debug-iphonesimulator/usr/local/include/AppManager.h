//
//  AppManager.h
//  Musubi
//
//  Created by Willem Bult on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EntityManager.h"

#define kSuperAppId @"mobisocial.musubi"

@class MApp;

@interface AppManager : EntityManager
- (id) initWithStore: (PersistentModelStore*) store;
- (MApp*) ensureAppWithAppId: (NSString*) appId;
- (MApp*) ensureSuperApp;
- (BOOL) isSuperApp: (MApp*) app;
@end
