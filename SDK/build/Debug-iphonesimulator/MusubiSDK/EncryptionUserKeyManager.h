//
//  EncryptionUserKeyManager.h
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EntityManager.h"

@class IBEncryptionScheme, IBEncryptionIdentity, IBEncryptionUserKey;
@class PersistentModelStore, MIdentity, MEncryptionUserKey;

@interface EncryptionUserKeyManager : EntityManager {
    IBEncryptionScheme* encryptionScheme;
}

@property (nonatomic) IBEncryptionScheme* encryptionScheme;

- (id) initWithStore: (PersistentModelStore*) store encryptionScheme: (IBEncryptionScheme*) es;


- (IBEncryptionUserKey *)encryptionKeyTo:(MIdentity *)to me:(IBEncryptionIdentity *)me;

@end
