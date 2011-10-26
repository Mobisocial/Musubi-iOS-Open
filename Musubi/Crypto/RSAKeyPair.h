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
//  RSAKeyPair.h
//  musubi
//
//  Created by Willem Bult on 10/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSData+Base64.h"
#import "RSAKey.h"

static UInt8 kPublicKeyIdentifier[] = "edu.stanford.mobisocial.musibi\0";
static UInt8 kPrivateKeyIdentifier[] = "edu.stanford.mobisocial.musubi\0";

@interface RSAKeyPair : NSObject {
    NSData* privateTag;
    NSData* publicTag;
    SecKeyRef privateKey;
    SecKeyRef publicKey;
}

- (id) initWithPublicTag: (NSData*) pubTag publicKey: (SecKeyRef) pub privateTag: (NSData*) priTag privateKey: (SecKeyRef) pri;

- (SecKeyRef) publicKeyRef;
- (SecKeyRef) privateKeyRef;
- (RSAPublicKey*) publicKey;
- (NSString*) publicKeyString;
- (RSAKey*) privateKey;
- (NSString*) privateKeyString;

@property (nonatomic,retain) NSData* privateTag;
@property (nonatomic,retain) NSData* publicTag;


+ (RSAKeyPair*) generateNewKeyPairWithPrivateId: (unsigned char*) privateId andPublicId: (unsigned char*) publicId;

@end
