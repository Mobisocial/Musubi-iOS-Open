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
//  RSAEncryptionScheme.h
//  musubi
//
//  Created by Willem Bult on 7/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <openssl/rsa.h>
#import "NSData+Base64.h"
#import "NSData+Crypto.h"
#import "CryptoIdentity.h"

@interface RSAKey : NSObject

@property (nonatomic,assign) RSA* rsa;

- (id) initWithEncoded: (NSData*) data;
- (id) initWithRSA: (RSA*) r;

- (NSData *) modulus;

- (NSData *) publicExponent;
- (NSData *) encryptNoPadding: (NSData*) input;
- (NSData *) encryptPKCS1Padding: (NSData*) input;

- (NSData *) sha1Digest;

+ (size_t) asn1TypeLengthForBuffer: (unsigned char*) buffer withLength: (int) length;
+ (NSData *) stripHeaderFromEncodedKey: (NSData*) enc;
+ (NSData *) prependHeaderToEncodedKey: (NSData*) enc;

@end


@interface RSAPrivateKey : RSAKey<NSObject> {
}

- (id) initWithDER: (NSData*) der;
- (NSData *) privateExponent;
- (NSData *) decryptNoPadding: (NSData*) input;
- (NSData *) decryptPKCS1Padding: (NSData *)input;
- (RSAKey *) publicKey;

+ (RSAPrivateKey *) privateKeyWithLength:(int)length;

@end

@interface RSAIdentity : NSObject<CryptoIdentity>
@property (nonatomic, strong) NSString* principal;
@property (nonatomic, strong) NSData* key;
@property (nonatomic, strong) NSData* hashed;
@property (nonatomic, assign) uint8_t authority;
@property (nonatomic, assign) uint64_t temporalFrame;

- (id) initWithAuthority:(uint8_t)a hashedKey:(NSData*) h;
- (id) initWithAuthority:(uint8_t)a principal:(NSString*) p;
- (id) initWithKey: (NSData*) key;
- (BOOL) equals: (RSAIdentity*) other;
@end

