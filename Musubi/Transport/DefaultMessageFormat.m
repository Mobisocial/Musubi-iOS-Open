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
#import "SBJson.h"

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

- (NSData*) packMessage: (Message*) msg {
    long long ts = (long long)([[msg timestamp] timeIntervalSince1970] * 1000);
    
    NSMutableDictionary* complemented = [NSMutableDictionary dictionaryWithDictionary: [[msg obj] data]];
    NSEnumerator *enumerator = [complemented keyEnumerator];
    id key;
    
    while ((key = [enumerator nextObject])) {
        id prop = [complemented objectForKey:key];
        
        if ([prop isKindOfClass:[NSData class]]) {
            [complemented setObject:[prop encodeBase64] forKey:key];
        }
    }
    
    [complemented setValue:[[msg obj] type] forKey:@"type"];
    [complemented setValue:[msg feedName] forKey:@"feedName"];
    [complemented setValue:[msg appId] forKey:@"appId"];
    [complemented setValue:[NSString stringWithFormat: @"%qi", ts] forKey:@"timestamp"];
    if ([msg parentHash] != nil) {
        [complemented setValue:[NSNumber numberWithLongLong:[[msg parentHash] longLongValue]] forKey:@"target_hash"];
        [complemented setValue:@"parent" forKey:@"target_relation"];
    }

    NSError* err = nil;
    SBJsonWriter* jsonWriter = [[[SBJsonWriter alloc] init] autorelease];
    NSString* json = [jsonWriter stringWithObject: complemented error:&err];
    if (err != nil)
        NSLog(@"Encoding error: %@", err);
    return [json dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData*) possiblyDecodeBase64: (NSString*) str {
    NSString* stripped = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    if ([stripped length] % 4 != 0)
        return nil;
    
    NSString* pattern = @"([A-Za-z0-9+/]{4})*([A-Za-z0-9+/]{2}[AEIMQUYcgkosw048]=|[A-Za-z0-9+/][AQgw]==)?";
    NSError* error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionAnchorsMatchLines error:&error];
    
    int matches = [regex numberOfMatchesInString:stripped options:0 range:NSMakeRange(0, [stripped length])];
    if (matches > 0) {
        @try {
            return [str decodeBase64];
        } @catch (NSException* e) {
        }
    }
    
    return nil;
}


- (SignedMessage*) unpackMessage: (NSData *)plain {
    SBJsonParser* parser = [[[SBJsonParser alloc] init] autorelease];
    NSDictionary* dict = [parser objectWithData: plain];
    
    double_t timestamp = [(NSString*)[dict objectForKey:@"timestamp"] doubleValue];
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:(int)(timestamp / 1000)];
    
    SignedMessage* msg = [[[SignedMessage alloc] init] autorelease];
    [msg setTimestamp: date];
    [msg setFeedName: [dict objectForKey:@"feedName"]];
    [msg setAppId: [dict objectForKey:@"appId"]];
    id parentHash = [dict objectForKey:@"target_hash"];
    if (![parentHash isKindOfClass:[NSString class]]) {
        parentHash = [parentHash description];
    }
        
    [msg setParentHash: parentHash];
    
    NSMutableDictionary* props = [[[NSMutableDictionary alloc] init] autorelease];
    NSEnumerator *enumerator = [dict keyEnumerator];
    id key;
    
    while ((key = [enumerator nextObject])) {
        if ([key isEqualToString:@"timestamp"] || [key isEqualToString:@"feedName"] || [key isEqualToString:@"appId"] || [key isEqualToString:@"type"] || [key isEqualToString:@"target_relation"] || [key isEqualToString:@"target_hash"])
            continue;
        
        id prop = [dict objectForKey:key];
        
        if ([key isEqualToString:@"data"] && [prop isKindOfClass:[NSString class]]) {
            NSData* decoded = [self possiblyDecodeBase64: prop];
            if (decoded != nil)
                prop = decoded;
        }
        
        [props setObject:prop forKey:key];
    }
    
    
    Obj* obj = [[[Obj alloc] initWithType:[dict objectForKey:@"type"]] autorelease];
    [obj setData: props];
    [msg setObj:obj];
    
    return msg;
}


- (EncodedMessage*) encodeMessage: (Message*) msg withKeyPair: (OpenSSLKeyPair*) keyPair {
    NSLog(@"%@", [[[keyPair publicKey] modulus] hex]);
    NSLog(@"%@", [[[keyPair publicKey] publicExponent] hex]);
    NSLog(@"%@", [[[keyPair privateKey] privateExponent] hex]);
    
    // the plain data
    NSData* plain = [self packMessage:msg];
    NSLog(@"Sending: %@", [self unpackMessage:plain]);
    
    // 128 bit AES key used to encrypt data
    NSData* aesKey = [NSData generateSecureRandomKeyOf:16];
    NSData* paddedAesKey = [self zeroPadData:aesKey toLength:RSA_size([keyPair publicKey].rsa)];
    
    NSMutableData* encoded = [NSMutableData data];
    
    // user public key (ASN.1 DER with header)
    NSData* userPubKey = [[keyPair publicKey] encoded];
    //NSLog(@"Sender public key: %@", userPubKey);
    [self appendLengthBigEndian16AndData:userPubKey to:encoded];
    
    // addressed public key count (BigEndian 16 bit)
    uint16_t pubKeysCount = CFSwapInt16HostToBig([[msg recipients] count]);
    [encoded appendBytes:&pubKeysCount length:sizeof(pubKeysCount)];
    
    for (NSString* pubKeyStr in [msg recipients]) {
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
    
    EncodedMessage* encodedMsg = [[[EncodedMessage alloc] init] autorelease];
    [encodedMsg setMessage: encoded];
    [encodedMsg setSignature: signature];
    
    return encodedMsg;
}

- (SignedMessage *)decodeMessage:(EncodedMessage *)msg withKeyPair:(OpenSSLKeyPair *)keyPair {
    const void* ptr = [[msg message] bytes];
    
    // Consume sender's public key
    NSData* senderKey = [self consumeLengthBigEndian16AndData:&ptr];
    
    // Consume number of keys
    uint16_t numberOfKeys = CFSwapInt16BigToHost(*(uint16_t*)ptr);
    ptr += sizeof(numberOfKeys);
    
    // These should be my personId bytes
    NSData* myPersonId = [[self personIdForPublicKey:[keyPair publicKey]] dataUsingEncoding:NSUTF8StringEncoding];
    NSData* myEncryptedAesKey = nil;
    
    NSMutableArray* recipients = [NSMutableArray arrayWithCapacity:numberOfKeys];
    
    for (int i=0; i<numberOfKeys; i++) {
        // Consume person id and encrypted AES key
        NSData* personId = [self consumeLengthBigEndian16AndData:&ptr];
        //NSLog(@"Person id: %@", personId);
        NSData* encryptedAesKey = [self consumeLengthBigEndian16AndData:&ptr];
        //NSLog(@"Enc AES: %@", encryptedAesKey);
        
        [recipients addObject:personId];
        
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
    
    // Hash is the BigEndian uint64 representation of the signature
    SignedMessage* signedMsg = [self unpackMessage: plain];
    [signedMsg setSender: [[Musubi sharedInstance] userWithPublicKey: senderKey]];
    [signedMsg setRecipients: recipients];
    [signedMsg setHash: [msg hash]];
    return signedMsg;
}



@end
