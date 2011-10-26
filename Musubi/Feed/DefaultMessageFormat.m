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
//  DefaultMessageFormat.m
//  musubi
//
//  Created by Willem Bult on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "DefaultMessageFormat.h"

@implementation DefaultMessageFormat : MessageFormat

- (void) appendLengthBigEndian16AndData: (NSData*) src to: (NSMutableData*) dest {
    // we need the number in big endian representation
    uint16_t len = CFSwapInt16HostToBig([src length]);
    [dest appendBytes:&len length:sizeof(len)];
    [dest appendData: src];
}

- (void) appendLengthBigEndian32AndData: (NSData*) src to: (NSMutableData*) dest {
    // we need the number in big endian representation
    uint32_t len = CFSwapInt32HostToBig([src length]);
    [dest appendBytes:&len length:sizeof(len)];
    [dest appendData: src];
}

- (NSString*) personIdForPublicKey: (OpenSSLPublicKey*) key {
    NSData* hash = [[key encoded] sha1HashWithLength:40];
    return [[hash hexString] substringToIndex:10];
}

- (NSData *) encodeMessage: (OutgoingMessage *) msg withKeyPair: (OpenSSLKeyPair *) keyPair {
    // the plain data
    NSData* plain = [msg message];
    
    // 128 bit AES key used to encrypt data
    NSData* aesKey = [NSData generateSecureRandomKeyOf:16];
    NSMutableData* encoded = [NSMutableData data];
    
    // user public key (ASN.1 DER with header)
    NSData* userPubKey = [[keyPair publicKey] encoded];
    NSLog(@"Public key: %@", userPubKey);
    [self appendLengthBigEndian16AndData:userPubKey to:encoded];
    
    // addressed public key count (BigEndian 16 bit)
    uint16_t pubKeysCount = CFSwapInt16HostToBig([[msg toPublicKeys] count]);
    [encoded appendBytes:&pubKeysCount length:sizeof(pubKeysCount)];
    
    for (NSString* pubKeyStr in [msg toPublicKeys]) {
        // addressee's person id (SHA1 hash of public key)
        OpenSSLPublicKey* pubKey = [[OpenSSLPublicKey alloc] initWithEncoded: [pubKeyStr decodeBase64]];
        NSData* personId = [[self personIdForPublicKey:pubKey] dataUsingEncoding:NSUTF8StringEncoding];
        [self appendLengthBigEndian16AndData:personId to:encoded];
        
        // AES key encrypted with addressee's public key (no padding)
        NSData* encryptedAesKey = [pubKey encryptNoPadding:aesKey];
        [self appendLengthBigEndian16AndData:encryptedAesKey to:encoded];
    }
    
    // 128 bit AES initalization vector
    NSData* aesInitVector = [NSData generateSecureRandomKeyOf:16];
    [self appendLengthBigEndian16AndData:aesInitVector to:encoded];
    
    // Cyphered data (AES128 + CBC + PKCS#7) with key and initialization vector
    NSData* cypher = [plain encryptWithAES128CBCPKCS7WithKey:aesKey andIV:aesInitVector];
    [self appendLengthBigEndian32AndData:cypher to:encoded];
    
    // Compute signature of payload with private key (SHA1 + RSA + PKCS#1)
    NSData* digest = [encoded sha1Digest];
    NSData* signature = [[keyPair privateKey] sign: digest];
    
    // Message = signature + encoded payload
    NSMutableData* message = [NSMutableData data];
    [self appendLengthBigEndian16AndData:signature to:message];
    [message appendData:encoded];
    
    return message;
}

@end
