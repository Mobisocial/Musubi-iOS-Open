//
//  MessageDecoder.h
//  Musubi
//
//  Created by Willem Bult on 2/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TransportDataProvider.h"

@class IBEncryptionScheme, IBSignatureScheme, MDevice, MIdentity, MEncodedMessage, MIncomingSecret;
@class Sender, Recipient, IncomingMessage;

@interface MessageDecoder : NSObject 

@property (nonatomic, strong) id<TransportDataProvider> transportDataProvider;
@property (nonatomic, strong) IBEncryptionScheme* encryptionScheme;
@property (nonatomic, strong) IBSignatureScheme* signatureScheme;

- (id)initWithTransportDataProvider:(id<TransportDataProvider>)tdp;
- (MIdentity*) addIdentityWithKey: (NSData*) key;
- (MDevice*) addDevice: (MIdentity*) ident withId:(NSData*)devId;
- (MIncomingSecret*) addIncomingSecretFrom: (MIdentity*) from atDevice: (MDevice*) device to: (MIdentity*) to sender: (Sender*) s recipient: (Recipient*) me;
- (void) checkSignatureForHash: (NSData*) hash withApp: (NSData*) app blind: (BOOL) blind forRecipients: (NSArray*) rs againstExpected: (NSData*) expected;
- (IncomingMessage*) decodeMessage: (MEncodedMessage*) encoded;


@end
