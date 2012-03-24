/*
 * Copyright 2012 The Stanford MobiSocial Laboratory
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


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

@interface MessageDecoder : NSObject {
    id<TransportDataProvider> transportDataProvider;
    IBEncryptionScheme* encryptionScheme;
    IBSignatureScheme* signatureScheme;
}

@property (nonatomic, retain) id<TransportDataProvider> transportDataProvider;
@property (nonatomic, retain) IBEncryptionScheme* encryptionScheme;
@property (nonatomic, retain) IBSignatureScheme* signatureScheme;

- (id)initWithTransportDataProvider:(id<TransportDataProvider>)tdp;
- (MIdentity*) addIdentityWithKey: (NSData*) key;
- (MDevice*) addDevice: (MIdentity*) ident withId:(NSData*)devId;
- (MIncomingSecret*) addIncomingSecretFrom: (MIdentity*) from atDevice: (MDevice*) device to: (MIdentity*) to sender: (Sender*) s recipient: (Recipient*) me;
- (void) checkSignatureForHash: (NSData*) hash withApp: (NSData*) app blind: (BOOL) blind forRecipients: (NSArray*) rs againstExpected: (NSData*) expected;
- (IncomingMessage*) decodeMessage: (MEncodedMessage*) encoded;


@end
