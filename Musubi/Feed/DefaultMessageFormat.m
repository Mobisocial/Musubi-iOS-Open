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

- (NSData*) consumeLengthBigEndian16AndData: (const void**) bytes {
    uint16_t len = CFSwapInt16BigToHost(** (uint16_t**)bytes);
    *bytes += sizeof(len);
    
    NSData* data = [NSData dataWithBytesNoCopy:*(void**)bytes length:len freeWhenDone:FALSE];
    *bytes += len;
    return data;
}

- (NSData*) consumeLengthBigEndian32AndData: (const void**) bytes {
    uint32_t len = CFSwapInt32BigToHost(** (uint32_t**)bytes);
    *bytes += sizeof(len);
    
    NSData* data = [NSData dataWithBytesNoCopy:*(void**)bytes length:len freeWhenDone:FALSE];
    *bytes += len;
    return data;
}

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
    return [[hash hex] substringToIndex:10];
}

- (NSData*) zeroPadData: (NSData*)data toLength: (int) length {
    if ([data length] > length) {
        @throw [NSException exceptionWithName:@"EncodingException" reason:@"Data length is longer than requested padded length" userInfo:nil];
    }
    
    unsigned char *buffer = malloc(length);
    bzero(buffer, length);
    bcopy((void*)[data bytes], buffer + length - [data length], [data length]);
    return [NSData dataWithBytesNoCopy:buffer length:length freeWhenDone:YES];
}

- (NSData *) encodeMessage: (OutgoingMessage *) msg withKeyPair: (OpenSSLKeyPair *) keyPair {
    // the plain data
    NSData* plain = [msg message];
    
    // 128 bit AES key used to encrypt data
    NSData* aesKey = [NSData generateSecureRandomKeyOf:16];
    NSData* paddedAesKey = [self zeroPadData:aesKey toLength:RSA_size([keyPair publicKey].rsa)];
    
    NSMutableData* encoded = [NSMutableData data];
    
    // user public key (ASN.1 DER with header)
    NSData* userPubKey = [[keyPair publicKey] encoded];
    //NSLog(@"Sender public key: %@", userPubKey);
    [self appendLengthBigEndian16AndData:userPubKey to:encoded];
    
    // addressed public key count (BigEndian 16 bit)
    uint16_t pubKeysCount = CFSwapInt16HostToBig([[msg toPublicKeys] count]);
    [encoded appendBytes:&pubKeysCount length:sizeof(pubKeysCount)];
    
    for (NSString* pubKeyStr in [msg toPublicKeys]) {
        // addressee's person id (SHA1 hash of public key)
        OpenSSLPublicKey* pubKey = [[[OpenSSLPublicKey alloc] initWithEncoded: [pubKeyStr decodeBase64]] autorelease];
        //NSLog(@"Pub key: %@", [pubKey encoded]);
        NSData* personId = [[self personIdForPublicKey:pubKey] dataUsingEncoding:NSUTF8StringEncoding];
        //NSLog(@"Person Id: %@", personId);
        [self appendLengthBigEndian16AndData:personId to:encoded];
        
        // AES key encrypted with addressee's public key (no padding)
        NSData* encryptedAesKey = [pubKey encryptNoPadding:paddedAesKey];
        //NSLog(@"Enc AES: %@", encryptedAesKey);
        [self appendLengthBigEndian16AndData:encryptedAesKey to:encoded];
    }

    //NSLog(@"AES Key: %@", aesKey);
    
    // 128 bit AES initalization vector
    NSData* aesInitVector = [NSData generateSecureRandomKeyOf:16];
    //NSLog(@"AES IV: %@", aesInitVector);
    [self appendLengthBigEndian16AndData:aesInitVector to:encoded];
    
    // Cyphered data (AES128 + CBC + PKCS#7) with key and initialization vector
    NSData* cypher = [plain encryptWithAES128CBCPKCS7WithKey:aesKey andIV:aesInitVector];
    //NSLog(@"Cypher: %@", cypher);
    [self appendLengthBigEndian32AndData:cypher to:encoded];
    
    // Compute signature of payload with private key (SHA1 + RSA + PKCS#1)
    NSData* digest = [encoded sha1Digest];
    NSData* signature = [[keyPair privateKey] sign: digest];
    //NSLog(@"Signature: %@", signature);
    
    // Message = signature + encoded payload
    NSMutableData* message = [NSMutableData data];
    [self appendLengthBigEndian16AndData:signature to:message];
    [message appendData:encoded];
    
    return message;
}

- (IncomingMessage *)decodeMessage:(NSData *)data withKeyPair :(OpenSSLKeyPair *)keyPair {
    const void* ptr = [data bytes];
    
    // Consume signature
    NSData* signature = [self consumeLengthBigEndian16AndData:&ptr];
    
    // Consume sender's public key
    NSData* senderKey = [self consumeLengthBigEndian16AndData:&ptr];
    //NSLog(@"Sender key: %@", senderKey);
    
    // Consume number of keys
    uint16_t numberOfKeys = CFSwapInt16BigToHost(*(uint16_t*)ptr);
    ptr += sizeof(numberOfKeys);
    
    // These should be my personId bytes
    NSData* myPersonId = [[self personIdForPublicKey:[keyPair publicKey]] dataUsingEncoding:NSUTF8StringEncoding];
    NSData* myEncryptedAesKey = nil;
    
    for (int i=0; i<numberOfKeys; i++) {
        // Consume person id and encrypted AES key
        NSData* personId = [self consumeLengthBigEndian16AndData:&ptr];
        //NSLog(@"Person id: %@", personId);
        NSData* encryptedAesKey = [self consumeLengthBigEndian16AndData:&ptr];
        //NSLog(@"Enc AES: %@", encryptedAesKey);
        
        // If this is my person id, then this is my encrypted AES key
        if ([personId isEqualToData:myPersonId])
            myEncryptedAesKey = encryptedAesKey;
    }
    
    if (myEncryptedAesKey == nil) {
        @throw [NSException exceptionWithName:@"Message decoding exception" reason:@"Message does not contain my person id" userInfo:nil];
    }
    
    // Decrypt the AES key. The 16 bytes of the key end up in the last section of the decrypted result
    NSData* aesKeyData = [[keyPair privateKey] decryptNoPadding:myEncryptedAesKey];
    //NSLog(@"AES key data: %@", aesKeyData);
    NSData* aesKey = [NSData dataWithBytesNoCopy:(void*)[aesKeyData bytes] + ([aesKeyData length] - 16) length:16 freeWhenDone:FALSE];
    //NSLog(@"AES key: %@", aesKey);

    // Consume the AES IV
    NSData* aesInitVector = [self consumeLengthBigEndian16AndData:&ptr];    
    //NSLog(@"AES IV: %@", aesInitVector);
    
    // Consume the cyphered data
    NSData* cypher = [self consumeLengthBigEndian32AndData:&ptr];
    //NSLog(@"Cypher: %@", cypher);

    // Decrypt with the AES key
    NSData* plain = [cypher decryptWithAES128CBCPKCS7WithKey:aesKey andIV:aesInitVector];
    
    return [IncomingMessage readFromJSON:plain withSender:[senderKey encodeBase64]];
}

@end
