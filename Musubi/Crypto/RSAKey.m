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
//  RSAKey.m
//  musubi
//
//  Created by Willem Bult on 10/21/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RSAKey.h"

@implementation RSAKey

@synthesize data;

- (id)initWithData: (NSData *)d {
    self = [super init];
    if (self != nil) {
        [self setData: d];
    }
    
    return self;
}

- (id)initFromKeyChainWithTag: (NSData*) tag {
    OSStatus sanityCheck = noErr;
    NSData * keyBits = nil;
        
    NSMutableDictionary * query = [[[NSMutableDictionary alloc] init] autorelease];
        
    [query setObject:(id)kSecClassKey forKey:(id)kSecClass];
    [query setObject:tag forKey:(id)kSecAttrApplicationTag];
    [query setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    [query setObject:[NSNumber numberWithBool:YES] forKey:(id)kSecReturnData];
        
    sanityCheck = SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef *)&keyBits);
        
    if (sanityCheck != noErr) {
        return nil;
    }
    
    return [self initWithData:keyBits];
}


size_t encodeLength(unsigned char * buf, size_t length) {
    
    // encode length in ASN.1 DER format
    if (length < 128) {
        buf[0] = length;
        return 1;
    }
    
    size_t i = (length / 256) + 1;
    buf[0] = i + 0x80;
    for (size_t j = 0 ; j < i; ++j) {         buf[i - j] = length & 0xFF;         length = length >> 8;
    }
    
    return i + 1;
}


- (SecKeyRef)secKeyRefWithTag: (NSString*) tag {
    return [self secKeyRefWithTag: tag andType:kSecAttrKeyClassPublic];
}

- (SecKeyRef)secKeyRefWithTag: (NSString*) tag andType:(id) keyType {
    NSData *tagData = [NSData dataWithBytes:[tag cStringUsingEncoding:NSUTF8StringEncoding] length:[tag length]];
        
    // Delete any old lingering key with the same tag
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    [query setObject:(id) kSecClassKey forKey:(id)kSecClass];
    [query setObject:(id) kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    [query setObject:tagData forKey:(id)kSecAttrApplicationTag];
    SecItemDelete((CFDictionaryRef)query);
        
    CFTypeRef keyRef = nil;
    // Add persistent version of the key to system keychain
    [query setObject:data forKey:(id)kSecValueData];
    [query setObject:keyType forKey:(id) kSecAttrKeyClass];
    [query setObject:[NSNumber numberWithBool:YES] forKey:(id) kSecReturnRef];
        
    OSStatus status = SecItemAdd((CFDictionaryRef)query, &keyRef);
    [query release];
        
    if (status != noErr) {
        return FALSE;
    }
        
    if (keyRef == nil) return(FALSE);
    return (SecKeyRef) keyRef;
}

@end


@implementation RSAPublicKey

@synthesize modulus, exponent;

const uint8_t UNSIGNED_FLAG_FOR_BYTE = 0x81;
const uint8_t UNSIGNED_FLAG_FOR_BYTE2 = 0x82;
const uint8_t UNSIGNED_FLAG_FOR_BIGNUM = 0x00;
const uint8_t SEQUENCE_TAG = 0x30;
const uint8_t INTEGER_TAG = 0x02;

NSArray* parseKey(NSData* key) {
    const uint8_t* bytes = [key bytes];
    const uint8_t bytesLen = [key length];
    uint8_t idx = 0;
    
    if (bytes[idx++] != SEQUENCE_TAG) {
        @throw [NSException exceptionWithName:@"KeyParseError" reason:@"Expected sequence tag" userInfo:nil];
    }
    
    size_t bodyLen;
    if (bytesLen > 128 && bytes[idx++] == UNSIGNED_FLAG_FOR_BYTE2) {
        bodyLen = bytes[idx++] * 256;
        bodyLen += bytes[idx++];
    } else {
        bodyLen = bytes[idx++];
    }
    
    if (bytes[idx++] != INTEGER_TAG) {
        @throw [NSException exceptionWithName:@"KeyParseError" reason:[NSString stringWithFormat:@"Expected integer tag, got %d", bytes[idx-1]] userInfo:nil];
    }
    
    size_t modLen = 0;
    if (bytes[idx] == UNSIGNED_FLAG_FOR_BYTE2) {
        idx++;
        
        modLen = bytes[idx++] * 256;
        modLen += bytes[idx++];
    } else {
        if (bytes[idx] == UNSIGNED_FLAG_FOR_BYTE) {
            idx++;
        }
        
        modLen = bytes[idx++];
    }
    
    NSData* modulus;
    if (bytes[idx] == UNSIGNED_FLAG_FOR_BIGNUM) {
        modulus = [NSData dataWithBytesNoCopy:(void*)bytes + idx + 1 length: modLen - 1];
    } else {
        modulus = [NSData dataWithBytesNoCopy:(void*)bytes + idx length: modLen];
    }
    
    idx += modLen;
    
    if (bytes[idx++] != INTEGER_TAG) {
        @throw [NSException exceptionWithName:@"KeyParseError" reason:@"Expected integer tag" userInfo:nil];
    }
    
    size_t expLen = bytes[idx++];
    NSData* exponent = [NSData dataWithBytesNoCopy:(void*)bytes+idx length: expLen];
    
    if (expLen + idx != bytesLen) {
        @throw [NSException exceptionWithName:@"KeyParseError" reason:[NSString stringWithFormat:@"%d bytes left at end", (bytesLen - expLen - idx)] userInfo:nil];
    }
    
    return [NSArray arrayWithObjects:modulus, exponent, nil];
}

NSData* stripPublicKeyHeader(NSData * d_key)
{
    // Skip ASN.1 public key header
    if (d_key == nil) return(nil);
    
    unsigned int len = [d_key length];
    if (!len) return(nil);
    
    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx    = 0;
    
    if (c_key[idx++] != 0x30) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    // PKCS #1 rsaEncryption szOID_RSA_RSA
    static unsigned char seqiod[] =
    { 0x30,   0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00 };
    if (memcmp(&c_key[idx], seqiod, 15)) return(nil);
    
    idx += 15;
    
    if (c_key[idx++] != 0x03) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    if (c_key[idx++] != '\0') return(nil);
    
    // Now make a new NSData from this buffer
    return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}

- (NSData *)keyWithHeader {
    NSLog(@"Before: %@", [self data]);
    
    static const unsigned char _encodedRSAEncryptionOID[15] = {
        
        /* Sequence of length 0xd made up of OID followed by NULL */
        0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00
        
    };
    
    unsigned char builder[15];
    NSMutableData * encKey = [[[NSMutableData alloc] init] autorelease];
    int bitstringEncLength;
    
    // When we get to the bitstring - how will we encode it?
    if  ([data length ] + 1  < 128 )
        bitstringEncLength = 1 ;
    else
        bitstringEncLength = (([data length ] +1 ) / 256 ) + 2 ; 
    
    // Overall we have a sequence of a certain length
    builder[0] = 0x30;    // ASN.1 encoding representing a SEQUENCE
    // Build up overall size made up of -
    // size of OID + size of bitstring encoding + size of actual key
    size_t i = sizeof(_encodedRSAEncryptionOID) + 2 + bitstringEncLength + [data length];
    size_t j = encodeLength(&builder[1], i);
    [encKey appendBytes:builder length:j +1];
    
    // First part of the sequence is the OID
    [encKey appendBytes:_encodedRSAEncryptionOID
                 length:sizeof(_encodedRSAEncryptionOID)];
    
    // Now add the bitstring
    builder[0] = 0x03;
    j = encodeLength(&builder[1], [data length] + 1);
    builder[j+1] = 0x00;
    [encKey appendBytes:builder length:j + 2];
    
    // Now the actual key
    [encKey appendData:data];
    
    
    NSLog(@"After: %@", stripPublicKeyHeader(encKey));
    
    return encKey;
}


- (id)initWithData: (NSData *)d {
    self = [super initWithData:d];
    if (self != nil) {
        NSArray* parts = parseKey(data);
        if (parts != nil) {
            [self setModulus: [parts objectAtIndex:0]];
            [self setExponent: [parts objectAtIndex:1]];
        }
    }
    
    return self;
}

- (id)initWithBase64:(NSString *)base64 {
    NSData* key = [base64 decodeBase64];
    NSData* strippedKey = stripPublicKeyHeader(key);
    return [self initWithData:strippedKey];
}

- (NSData*) pkcs8Format {
    
}

@end