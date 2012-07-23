//
//  TransportManager.h
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TransportDataProvider.h"

@class PersistentModelStore, IBEncryptionScheme, IBSignatureScheme;
@class IdentityManager, EncryptionUserKeyManager, SignatureUserKeyManager;

@interface TransportManager : NSObject<TransportDataProvider>

@property (nonatomic, strong) PersistentModelStore* store;
@property (nonatomic, strong) IBEncryptionScheme* encryptionScheme;
@property (nonatomic, strong) IBSignatureScheme* signatureScheme;
@property (nonatomic, assign) uint64_t deviceName;
@property (nonatomic, strong) IdentityManager* identityManager;
@property (nonatomic, strong) EncryptionUserKeyManager* encryptionUserKeyManager;
@property (nonatomic, strong) SignatureUserKeyManager* signatureUserKeyManager;

- (id) initWithStore: (PersistentModelStore*) store encryptionScheme: (IBEncryptionScheme*) es signatureScheme: (IBSignatureScheme*) ss deviceName: (uint64_t) devName;

@end
