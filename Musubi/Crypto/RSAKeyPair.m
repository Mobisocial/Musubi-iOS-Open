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
//  RSAKeyPair.m
//  musubi
//
//  Created by Willem Bult on 10/12/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RSAKeyPair.h"


@implementation RSAKeyPair

@synthesize privateTag, publicTag;

- (id)initWithPublicTag:(NSData *)pubTag publicKey:(SecKeyRef)pub privateTag:(NSData *)priTag privateKey:(SecKeyRef)pri {
    self = [super init];
    if (self != nil) {
        publicKey = pub;
        privateKey = pri;
        
        [self setPrivateTag: priTag];
        [self setPublicTag: pubTag];
        
        CFRetain(publicKey);
        CFRetain(privateKey);        
    }
    
    return self;
}

- (void)dealloc {
    CFRelease(publicKey);
    CFRelease(privateKey);
    [privateTag release];
    [publicTag release];
    
    [super dealloc];
}

- (SecKeyRef) privateKeyRef {
    return privateKey;
}

- (SecKeyRef)publicKeyRef {
    return publicKey;
}

- (RSAKey *)privateKey {
    return [[RSAKey alloc] initFromKeyChainWithTag:privateTag];
}

- (NSString *)privateKeyString {
    return [[[self privateKey] keyWithHeader] encodeBase64];
}

- (RSAPublicKey *)publicKey {
    return [[RSAPublicKey alloc] initFromKeyChainWithTag:publicTag];
}

- (NSString *)publicKeyString {
    return [[[self publicKey] keyWithHeader] encodeBase64];
}


+ (RSAKeyPair *)generateNewKeyPairWithPrivateId:(unsigned char *)privateId andPublicId:(unsigned char *)publicId {
    OSStatus status = noErr;
    
    NSMutableDictionary *privateKeyAttr = [[[NSMutableDictionary alloc] init] autorelease];
    NSMutableDictionary *publicKeyAttr = [[[NSMutableDictionary alloc] init] autorelease];
    NSMutableDictionary *keyPairAttr = [[[NSMutableDictionary alloc] init] autorelease];
    
    NSData * publicTag = [NSData dataWithBytes:publicId
                                        length:strlen((const char *)publicId)];
    NSData * privateTag = [NSData dataWithBytes:privateId
                                         length:strlen((const char *)privateId)];
    
    SecKeyRef publicKey = NULL;
    SecKeyRef privateKey = NULL;
    
    [keyPairAttr setObject:(id)kSecAttrKeyTypeRSA
                    forKey:(id)kSecAttrKeyType];
    [keyPairAttr setObject:[NSNumber numberWithInt:1024]
                    forKey:(id)kSecAttrKeySizeInBits];

    [privateKeyAttr setObject:[NSNumber numberWithBool:YES]
                       forKey:(id)kSecAttrIsPermanent];
    [privateKeyAttr setObject:privateTag
                       forKey:(id)kSecAttrApplicationTag];
    
    [publicKeyAttr setObject:[NSNumber numberWithBool:YES]
                      forKey:(id)kSecAttrIsPermanent];
    [publicKeyAttr setObject:publicTag
                      forKey:(id)kSecAttrApplicationTag];
    
    [keyPairAttr setObject:privateKeyAttr
                    forKey:(id)kSecPrivateKeyAttrs];
    [keyPairAttr setObject:publicKeyAttr
                    forKey:(id)kSecPublicKeyAttrs];

    status = SecKeyGeneratePair((CFDictionaryRef) keyPairAttr, &publicKey, &privateKey);
    
    RSAKeyPair* kp = [[[RSAKeyPair alloc] initWithPublicTag:publicTag publicKey:publicKey privateTag:privateTag privateKey:privateKey] autorelease];
    
    NSLog(@"PuK: %@", publicKey);
    NSLog(@"PrK: %@", privateKey);
    
    if(publicKey) CFRelease(publicKey);
    if(privateKey) CFRelease(privateKey);
    
    return kp;
}


@end
