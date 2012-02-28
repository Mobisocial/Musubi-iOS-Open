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
//  TransportDataProvider.h
//  Musubi
//
//  Created by Willem Bult on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MIdentity.h"
#import "MDevice.h"
#import "MOutgoingSecret.h"
#import "MEncodedMessage.h"
#import "OutgoingMessage.h"
#import "IBEncryptionScheme.h"

@interface TransportDataProvider : NSObject

- (long) deviceName;

- (long) signatureTimeForIdentity: (MIdentity*) ident;
- (long) encryptionTimeForIdentity: (MIdentity*) ident;

- (BOOL) isMe: (IBEncryptionIdentity*) ident;

- (MOutgoingSecret *)lookupOutgoingSecretFrom:(MIdentity *)from to:(MIdentity *)to fromIdent:(IBEncryptionIdentity *)me toIdent:(IBEncryptionIdentity *)you;
- (IBEncryptionUserKey*) signatureKeyForIdentity:(MIdentity *)ident andIBEIdentity: ibeIdent;
- (void) insertOutgoingSecret: (MOutgoingSecret*) os from: (IBEncryptionIdentity*) from to: (IBEncryptionIdentity*) to;
- (void) incrementSequenceNumberTo: (MIdentity*) to;
- (MDevice*) addDevice: (MIdentity*) device withName: (long) deviceName;
- (void) insertEncodedMessage: (MEncodedMessage*) encoded forOutgoingMessage: (OutgoingMessage*) om;
- (void) storeSequenceNumbers: (NSDictionary*) seqNumbers forEncodedMessage: (MEncodedMessage*) encoded;
@end
