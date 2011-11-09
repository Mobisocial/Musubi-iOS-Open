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
//  OpenSSLKey.h
//  musubi
//
//  Created by Willem Bult on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <openssl/rsa.h>
#import "NSData+Base64.h"

@interface OpenSSLKey : NSObject {
    RSA* rsa;
}

@property (nonatomic,assign) RSA* rsa;

- (id) initWithRSA: (RSA*) r;
- (NSData *) modulus;

@end



@interface OpenSSLPrivateKey : OpenSSLKey {
}

- (id) initWithDER: (NSData*) der;
- (NSData *) privateExponent;
- (NSData *) der;
- (NSData *) sign: (NSData*) data;
- (NSData *) decryptNoPadding: (NSData*) input;
- (NSData *) decryptPKCS1Padding: (NSData *)input;
+ (OpenSSLPrivateKey *) privateKeyWithLength:(int)length;

@end


@interface OpenSSLPublicKey : OpenSSLKey {    
}

- (id) initWithEncoded: (NSData*) data;
- (NSData *) publicExponent;
- (NSData *) encoded;
- (NSData *) encryptNoPadding: (NSData*) input;
- (NSData *) encryptPKCS1Padding: (NSData*) input;

+ (OpenSSLPublicKey *) publicKeyFromPrivateKey:(OpenSSLPrivateKey *)privateKey;
+ (size_t) asn1TypeLengthForBuffer: (unsigned char*) buffer withLength: (int) length;
+ (NSData *) stripHeaderFromEncodedKey: (NSData*) enc;
+ (NSData *) prependHeaderToEncodedKey: (NSData*) enc;


@end


@interface OpenSSLKeyPair : NSObject {
    OpenSSLPublicKey* publicKey;
    OpenSSLPrivateKey* privateKey;
}

@property (nonatomic, retain) OpenSSLPrivateKey* privateKey;
@property (nonatomic, retain) OpenSSLPublicKey* publicKey;

- (id) initWithPrivateKey: (OpenSSLPrivateKey*) privKey andPublicKey: (OpenSSLPublicKey*) pubKey;
+ (OpenSSLKeyPair*) keyPairWithLength: (int) bits;

@end