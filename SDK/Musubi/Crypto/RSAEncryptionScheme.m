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
//  RSAEncryptionScheme.m
//  musubi
//
//  Created by Willem Bult on 7/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RSAEncryptionScheme.h"

@implementation RSAEncryptionScheme


@end


@implementation RSAIdentity

@synthesize key, principal, hashed, authority;

- (id)initWithAuthority:(uint8_t)a principal:(NSString *)p {
    NSData* hash = [[p dataUsingEncoding:NSUTF8StringEncoding] sha256Digest];
    
    self = [self initWithAuthority:a hashedKey:hash];
    if (self != nil) {
        [self setPrincipal: p];
    }
    return self;
}

- (id)initWithAuthority:(uint8_t)a hashedKey:(NSData *)h {
    self = [super init];
    if (self != nil) {
        [self setAuthority:a];
        [self setHashed:h];
        
        uint8_t a8bit = (uint8_t)a;
        
        NSMutableData* k = [NSMutableData data];
        [k appendBytes:&a8bit length:1];
        [k appendData:h];
        
        [self setKey:k];
        [self setTemporalFrame:0];
    }
    return self;
}

- (id)initWithKey:(NSData *)k {
    self = [super init];
    if (self != nil) {
        [self setKey: k];
        
        [self setAuthority:*(uint8_t*)[key bytes]];
        [self setHashed: [NSData dataWithBytes: [key bytes]+sizeof(uint8_t) length:32]];
        [self setTemporalFrame:0];
    }
    
    return self;
}
- (BOOL) equals: (RSAIdentity*) other {
    return authority == other.authority && [hashed isEqualToData:other.hashed];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<RSAIdentity: %d, %@, %@>", authority, principal, hashed];
}

- (BOOL) isEqual:(id)object
{
    if(![object isKindOfClass:[RSAIdentity class]])
        return NO;
    return [self equals:object];
}

- (NSUInteger)hash
{
    return [self.key hash];
}


@end


@implementation RSAKey

@synthesize rsa = _rsa;

- (id)initWithRSA:(RSA *)r {
    self = [super init];
    if (self != nil) {
        _rsa = r;
    }
    return self;
}

- (NSData *)modulus {
    unsigned char *data = malloc(BN_num_bytes(_rsa->n));
    int length = BN_bn2bin(_rsa->n, data);
    return [NSData dataWithBytesNoCopy:data length:length];
}


- (id)initWithEncoded:(NSData *)data {
    self = [super init];
    if (self != nil) {
        NSData* stripped = [RSAKey stripHeaderFromEncodedKey: data];
        
        const unsigned char* p = [stripped bytes];
        long len = [data length];
        if (!d2i_RSAPublicKey(&_rsa, &p, len) ) {
            NSLog(@"Couldn't read DER ASN.1 key");
            return nil;
        }
        
        return self;
    }
    
    return self;
}

- (NSData *)raw {
    int len = i2d_RSAPublicKey(_rsa, 0);
    unsigned char *der = malloc(len);
    unsigned char *p = der;
    
    i2d_RSAPublicKey(_rsa, &p);
    NSData* encoded = [NSData dataWithBytesNoCopy:der length:len];
    return [RSAKey prependHeaderToEncodedKey:encoded];
}

- (NSData *)publicExponent {
    unsigned char *data = malloc(BN_num_bytes(_rsa->e));
    int length = BN_bn2bin(_rsa->e, data);
    return [NSData dataWithBytesNoCopy:data length:length];
}

- (NSData *)encryptNoPadding:(NSData *)input {
    int length = RSA_size(_rsa);
    if (![input length] == length) {
        @throw [NSException exceptionWithName:@"CryptError" reason:@"Input length is not equal to the RSA block size" userInfo:nil];
    }
    unsigned char *cipher = malloc(length);
    
    RSA_public_encrypt(length, [input bytes], cipher, _rsa, RSA_NO_PADDING);
    return [NSData dataWithBytesNoCopy:cipher length:length freeWhenDone:YES];
}

- (NSData *)encryptPKCS1Padding:(NSData *)input {
    int length = RSA_size(_rsa);
    
    unsigned char *cipher = malloc(RSA_size(_rsa));
    RSA_public_encrypt(MIN(length - 12, [input length]), [input bytes], cipher, _rsa, RSA_PKCS1_PADDING);
    return [NSData dataWithBytesNoCopy:cipher length:length];
}

- (NSData *)encrypt:(NSData *)data {
    return [self encryptNoPadding: data];
}

- (NSData *)sha1Digest {
    return [[self raw] sha1Digest];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Public RSA Key:\nModulus: %@\nPublic exponent: %@", [self modulus], [self publicExponent]];
}


+ (NSData *)stripHeaderFromEncodedKey:(NSData *)enc {
    // Skip ASN.1 public key header
    if (enc == nil) return(nil);
    
    unsigned int len = [enc length];
    if (!len) return(nil);
    
    unsigned char *c_key = (unsigned char *)[enc bytes];
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

+ (size_t) asn1TypeLengthForBuffer:(unsigned char *)buffer withLength:(int)length {
    
    // encode length in ASN.1 DER format
    if (length < 128) {
        buffer[0] = length;
        return 1;
    }
    
    size_t i = (length / 256) + 1;
    buffer[0] = i + 0x80;
    for (size_t j = 0 ; j < i; ++j) {
        buffer[i - j] = length & 0xFF;
        length = length >> 8;
    }
    
    return i + 1;
}


+ (NSData *)prependHeaderToEncodedKey:(NSData *)enc {
    static const unsigned char _encodedRSAEncryptionOID[15] = {
        
        /* Sequence of length 0xd made up of OID followed by NULL */
        0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00
        
    };
    
    unsigned char builder[15];
    NSMutableData * encKey = [[NSMutableData alloc] init];
    int bitstringEncLength;
    
    // When we get to the bitstring - how will we encode it?
    if  ([enc length ] + 1  < 128 )
        bitstringEncLength = 1 ;
    else
        bitstringEncLength = (([enc length ] +1 ) / 256 ) + 2 ; 
    
    // Overall we have a sequence of a certain length
    builder[0] = 0x30;    // ASN.1 encoding representing a SEQUENCE
    // Build up overall size made up of -
    // size of OID + size of bitstring encoding + size of actual key
    size_t i = sizeof(_encodedRSAEncryptionOID) + 2 + bitstringEncLength + [enc length];
    
    size_t j = [RSAKey asn1TypeLengthForBuffer:&builder[1] withLength:i];
    [encKey appendBytes:builder length:j +1];
    
    // First part of the sequence is the OID
    [encKey appendBytes:_encodedRSAEncryptionOID
                 length:sizeof(_encodedRSAEncryptionOID)];
    
    // Now add the bitstring
    builder[0] = 0x03;
    j = [RSAKey asn1TypeLengthForBuffer:&builder[1] withLength: [enc length] + 1];
    builder[j+1] = 0x00;
    [encKey appendBytes:builder length:j + 2];
    [encKey appendData: enc];
    
    return encKey;
}


@end


@implementation RSAPrivateKey

- (id)initWithDER:(NSData *)der {
    self = [super init];
    if (self != nil) {
        const unsigned char* p = [der bytes];
        long len = [der length];
        RSA* rsa = self.rsa;
        if (!d2i_RSAPrivateKey(&rsa, &p, len) ) {
            NSLog(@"Couldn't read DER ASN.1 key");
            return nil;
        }
        
        return self;
    }
    
    return self;
}

- (NSData *)privateExponent {
    RSA* rsa = self.rsa;
    unsigned char *data = malloc(BN_num_bytes(rsa->d));
    int length = BN_bn2bin(rsa->d, data);
    return [NSData dataWithBytesNoCopy:data length:length];
}

- (NSData *)raw {
    RSA* rsa = self.rsa;
    // Return raw key data in DER format
    
    int len = i2d_RSAPrivateKey(rsa, 0);
    unsigned char *der = malloc(len);
    unsigned char *p = der;
    
    i2d_RSAPrivateKey(rsa, &p);
    return [NSData dataWithBytesNoCopy:der length:len];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Private RSA Key:\nModulus: %@\nPrivate exponent: %@", [self modulus], [self privateExponent]];
}

- (RSAKey *) publicKey {
    //TODO: copy rsa and strip out private exponent
	unsigned long check = RSA_check_key(self.rsa);
	if (check != 1)
	{
		NSLog(@"RSA_check_key() failed with result %lu!", check);
		return nil;
	}
    
    return [[RSAKey alloc] initWithRSA: self.rsa];
}


- (NSData *)sign: (NSData*) data
{
    RSA* rsa = self.rsa;
    unsigned char *input = (unsigned char *)[data bytes];
    unsigned char *outbuf;
    int outlen, inlen;
    inlen = [data length];
	
	// RSA_check_key() returns 1 if rsa is a valid RSA key, and 0 otherwise.
	unsigned long check = RSA_check_key(rsa);
	if(check != 1)
	{
		NSLog(@"RSA_check_key() failed with result %lu!", check);
		return nil;
	}			
	
	// RSA_size() returns the RSA modulus size in bytes.
	// It can be used to determine how much memory must be allocated for an RSA encrypted value.
	
	outbuf = (unsigned char *)malloc(RSA_size(rsa));
	
	if(!(outlen = RSA_private_encrypt(inlen, input, (unsigned char*)outbuf, rsa, RSA_PKCS1_PADDING)))
	{
		NSLog(@"RSA_private_encrypt failed!");
		return nil;
	}
	
	if(outlen == -1)
	{
		NSLog(@"Encrypt error: %s (%s)",
			  ERR_error_string(ERR_get_error(), NULL),
			  ERR_reason_error_string(ERR_get_error()));
		return nil;
	}
	
    NSData* signature = [NSData dataWithBytes:outbuf length:outlen];
    
	// Release the outbuf, since it was malloc'd
    if(outbuf) {
        free(outbuf);
    }
    
    return signature;
}

- (NSData *)decryptNoPadding:(NSData *)input {
    RSA* rsa = self.rsa;
    
    int length = RSA_size(rsa);    
    unsigned char *buffer = malloc(length);
    bzero(buffer, length);
    
    RSA_private_decrypt([input length], [input bytes], buffer, rsa, RSA_NO_PADDING);
    return [NSData dataWithBytesNoCopy:buffer length:length];
}

- (NSData *)decryptPKCS1Padding:(NSData *)input {
    RSA* rsa = self.rsa;
    
    int length = RSA_size(rsa);    
    unsigned char *buffer = malloc(length);
    bzero(buffer, length);
    
    RSA_private_decrypt([input length], [input bytes], buffer, rsa, RSA_PKCS1_PADDING);
    return [NSData dataWithBytesNoCopy:buffer length:length];
}

- (NSData *)decrypt:(NSData *)data {
    return [self decryptNoPadding: data];
}

+ (RSAPrivateKey*)privateKeyWithLength:(int)length
{
    RSA *key = NULL;
    do {
        key = RSA_generate_key(length, RSA_F4, NULL, NULL);
    } while (1 != RSA_check_key(key));
    
    return [[RSAPrivateKey alloc] initWithRSA:key];
}

@end