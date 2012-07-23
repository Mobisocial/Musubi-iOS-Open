//
//  UserKeyManager.h
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EntityManager.h"

@class PersistentModelStore, MSignatureUserKey, MIdentity;
@class IBSignatureScheme, IBEncryptionIdentity, IBSignatureUserKey;

@interface SignatureUserKeyManager : EntityManager

@property (nonatomic, strong) IBSignatureScheme* signatureScheme;

- (id) initWithStore: (PersistentModelStore*) store signatureScheme: (IBSignatureScheme*) ss;

- (void) createSignatureUserKey:(MSignatureUserKey*)signatureKey;
- (void) updateSignatureUserKey:(MSignatureUserKey*)signatureKey;
- (IBSignatureUserKey*) signatureKeyFrom: (MIdentity*) from me: (IBEncryptionIdentity*) to;

@end
