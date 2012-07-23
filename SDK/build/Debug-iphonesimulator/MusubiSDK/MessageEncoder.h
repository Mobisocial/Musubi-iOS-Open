//
//  MessageEncoder.h
//  Musubi
//
//  Created by Willem Bult on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TransportDataProvider.h"

@class IBEncryptionScheme, IBSignatureScheme, MEncodedMessage, MOutgoingSecret;

@interface MessageEncoder : NSObject

@property (nonatomic, strong) id<TransportDataProvider> transportDataProvider;
@property (nonatomic, strong) IBEncryptionScheme* encryptionScheme;
@property (nonatomic, strong) IBSignatureScheme* signatureScheme;
@property (nonatomic, readonly, assign) uint64_t deviceName;

- (id)initWithTransportDataProvider:(id<TransportDataProvider>)tdp;
- (NSData*) computeFullSignatureForRecipients: (NSArray*) rcpts hash: (NSData*) h app: (NSData*) a blind: (BOOL) b;
- (MOutgoingSecret*) outgoingSecretFrom: (MIdentity*) from to: (MIdentity*) to fromIdent: (IBEncryptionIdentity*) me toIdent: (IBEncryptionIdentity*) you;
- (MEncodedMessage*) encodeOutgoingMessage: (OutgoingMessage*) om;
@end
