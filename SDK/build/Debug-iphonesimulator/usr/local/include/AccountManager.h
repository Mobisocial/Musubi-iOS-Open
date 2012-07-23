//
//  AccountManager.h
//  Musubi
//
//  Created by Willem Bult on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EntityManager.h"

@class MAccount;

@interface AccountManager : EntityManager

- (id) initWithStore: (PersistentModelStore*) s;
- (NSArray*) accountsWithType: (NSString*) type;
- (NSArray*) claimedAccounts;
- (MAccount*) accountWithName: (NSString*) name andType: (NSString*) type;
- (void) deleteAccount: (MAccount*) account;
@end
