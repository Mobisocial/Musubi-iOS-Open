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
//  MessageEncoder.h
//  Musubi
//
//  Created by Willem Bult on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PersistentModelStore.h"
#import "MEncodedMessage.h"
#import "MOutgoingSecret.h"
#import "OutgoingMessage.h"
#import "TransportDataProvider.h"


@interface MessageEncoder : NSObject {
    id<TransportDataProvider> transportDataProvider;
    IBEncryptionScheme* encryptionScheme;
    IBSignatureScheme* signatureScheme;
    long deviceName;
}

@property (nonatomic, retain) id<TransportDataProvider> transportDataProvider;
@property (nonatomic, retain) IBEncryptionScheme* encryptionScheme;
@property (nonatomic, retain) IBSignatureScheme* signatureScheme;

- (id)initWithTransportDataProvider:(id<TransportDataProvider>)tdp;
- (NSData*) computeFullSignatureForRecipients: (NSArray*) rcpts hash: (NSData*) h app: (NSData*) a blind: (BOOL) b;
- (MOutgoingSecret*) outgoingSecretFrom: (MIdentity*) from to: (MIdentity*) to fromIdent: (IBEncryptionIdentity*) me toIdent: (IBEncryptionIdentity*) you;
- (MEncodedMessage*) encodeOutgoingMessage: (OutgoingMessage*) om;
@end
