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
//  MusubiAppTest.m
//  MusubiAppTest
//
//  Created by Willem Bult on 2/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MusubiAppTest.h"
#import "IBEncryptionScheme.h"
#import "MEncodedMessage.h"
#import "BSONEncoder.h"
#import "Recipient.h"

#include <stdio.h>
#include <openssl/sha.h>
#include <string.h>
#include "ibesig.h"
#include "pbc.h"

@implementation MusubiAppTest

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testIBESig
{
    printf("generating parameters\n");
    char* mk_data = NULL;
    int mk_length = 0;
    ibesig_public_parameters* pp = ibesig_global_public_parameters(&mk_data, &mk_length);
    
    printf("serializing and deserializing\n");
    char* pp_data = NULL;
    int pp_length = 0;
    ibesig_serialize_parameters(&pp_data, &pp_length, pp);
    ibesig_clear_public_parameters(pp);
    pp = ibesig_unserialize_parameters(pp_data, pp_length);
    
    element_t mk;
    element_init_Zr(mk, pp->pairing);
    element_from_bytes(mk, mk_data);
    element_printf("master key = %B\n", mk);
    element_clear(mk);
    
    char* uid_data = "tpurtell@stanford.edu";
    int uid_length = strlen(uid_data);
    
    printf("computing personal key\n");
    char* uk_data = NULL;
    int uk_length = 0;
    ibesig_keygen(&uk_data, &uk_length, pp, mk_data, mk_length, uid_data, uid_length);
    
    //deserialize the user secret
    element_t g_huid;
    element_init_G1(g_huid, pp->pairing);
    element_from_bytes_compressed(g_huid, (unsigned char*)uk_data);
    element_printf("uk = %B\n", g_huid);
    element_clear(g_huid);
    
    char* message_hash_data = "01234567890123456789012345678901";
    int message_hash_length = SHA256_DIGEST_LENGTH;
    
    printf("computing a signature\n");
    char* sig_data = NULL;
    int sig_length = 0;
    ibesig_sign(&sig_data, &sig_length, pp, uk_data, uk_length, uid_data, uid_length, message_hash_data, message_hash_length);
    
    element_t u;
    element_init_G1(u, pp->pairing);
    element_from_bytes_compressed(u, (unsigned char*)sig_data);
    element_t v;
    element_init_Zr(v, pp->pairing);
    element_from_bytes(v, (unsigned char*)sig_data + element_length_in_bytes_compressed(u));
    element_printf("sig u = %B\n", u);
    element_printf("sig v = %B\n", v);
    element_clear(u);
    element_clear(v);
    
    printf("verifying a signature\n");
    int result = ibesig_verify(pp, sig_data, sig_length, uid_data, uid_length, message_hash_data, message_hash_length);
    printf("result = %d\n", result);
    
    printf("verifying a bad signature\n");
    sig_data[sizeof(void*)]++;
    result = ibesig_verify(pp, sig_data, sig_length, uid_data, uid_length, message_hash_data, message_hash_length);
    printf("result = %d\n", result);
    
    ibesig_clear_public_parameters(pp);
    free(mk_data);
    free(uk_data);
    free(sig_data);
    return 0;
}

- (void)testEncryption
{
    //    STFail(@"Unit tests are not implemented yet in MusubiAppTest");
    
    IBEncryptionScheme* scheme = [[IBEncryptionScheme alloc] init];
    IBEncryptionMasterKey* mk = [scheme masterKey];
    
    IBEncryptionScheme* userScheme = [[IBEncryptionScheme alloc] initWithParameters: [scheme parameters]];
    IBEncryptionScheme* loadedScheme = [[IBEncryptionScheme alloc] initWithParameters: [scheme parameters] andMasterKey:mk];
    
    NSData* hashedKey = [@"wbult@stanford.edu" dataUsingEncoding:NSUTF8StringEncoding];
    IBEncryptionIdentity* ident = [[IBEncryptionIdentity alloc] initWithAuthority:kIBEncryptionIdentityAuthorityEmail andHashedKey:hashedKey andTemporalFrame:1];
    
    IBEncryptionUserKey* userKey = [loadedScheme userKeyWithIdentity:ident];
    IBEncryptionConversationKey* convKey = [userScheme randomConversationKeyWithIdentity:ident];
    
    NSData* key = [userScheme decryptConversationKey:convKey withUserKey:userKey];
    STAssertTrue([key isEqualToData:[convKey raw]], @"encrypt => decrypt (right identity) : failed to match conversation key");
    
    NSData* otherHashedKey = [@"stfan@stanford.edu" dataUsingEncoding:NSUTF8StringEncoding];
    IBEncryptionIdentity* otherIdent = [[IBEncryptionIdentity alloc] initWithAuthority:kIBEncryptionIdentityAuthorityEmail andHashedKey:otherHashedKey andTemporalFrame:1];
    IBEncryptionUserKey* otherUserKey = [loadedScheme userKeyWithIdentity:otherIdent];
    
    key = [userScheme decryptConversationKey:convKey withUserKey:otherUserKey];
    STAssertFalse([key isEqualToData:[convKey raw]], @"encrypt => decrypt (wrong identity): failed to mismatch conversation key");
}

- (void)testSignature
{
    IBSignatureScheme* scheme = [[IBSignatureScheme alloc] init];
    IBEncryptionMasterKey* mk = [scheme masterKey];
    
    IBSignatureScheme* userScheme = [[IBSignatureScheme alloc] initWithParameters: [scheme parameters]];
    IBSignatureScheme* loadedScheme = [[IBSignatureScheme alloc] initWithParameters: [scheme parameters] andMasterKey:mk];
    
    NSData* hashedKey = [@"wbult@stanford.edu" dataUsingEncoding:NSUTF8StringEncoding];
    IBEncryptionIdentity* ident = [[IBEncryptionIdentity alloc] initWithAuthority:kIBEncryptionIdentityAuthorityEmail andHashedKey:hashedKey andTemporalFrame:1];
    
    NSData* hash = [NSData dataWithBytes:"01234567890123456789012345678901" length:SHA256_DIGEST_LENGTH];
    IBEncryptionUserKey* userKey = [loadedScheme userKeyWithIdentity:ident];
    
    NSData* signature = [userScheme signHash: hash withUserKey: userKey andIdentity: ident];
    BOOL ok = [userScheme verifySignature: signature forHash: hash withIdentity: ident];
    
    STAssertTrue(ok, @"sign => verify (right identity) : failed to match");
    
    //destroy signature
    ((char*)[signature bytes])[9]++;
    ok = [userScheme verifySignature: signature forHash: hash withIdentity: ident];
    STAssertFalse(ok, @"sign => verify (wrong identity) : failed to mismatch");
}

- (void)testBSONEncodeDecodeSecret
{
    Secret* s = [[Secret alloc] init];
    [s setH:[@"hash" dataUsingEncoding:NSUTF8StringEncoding]];
    [s setQ:1234];
    [s setK:[@"key" dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSData* bson = [BSONEncoder encodeSecret: s];
    STAssertNotNil(bson, @"BSON should not be nil");
    
    Secret* s2 = [BSONEncoder decodeSecret:bson];
    
    STAssertTrue([s.h isEqualToData: s2.h], @"Secret H don't match");
    STAssertTrue(s.q == s2.q, @"Secret Q don't match");
    STAssertTrue([s.k isEqualToData: s2.k], @"Secret K don't match");
}

- (void)testBSONEncodeDecodeMessage
{
    Recipient* r1 = [[Recipient alloc] init];
    [r1 setI: [@"serialized hashed identity 1" dataUsingEncoding:NSUTF8StringEncoding]];
    [r1 setK: [@"encrypted key block 1" dataUsingEncoding:NSUTF8StringEncoding]];
    [r1 setS: [@"signature block 1" dataUsingEncoding:NSUTF8StringEncoding]];
    [r1 setD: [@"encrypted secrets 1" dataUsingEncoding:NSUTF8StringEncoding]];
    
    Recipient* r2 = [[Recipient alloc] init];
    [r2 setI: [@"serialized hashed identity 2" dataUsingEncoding:NSUTF8StringEncoding]];
    [r2 setK: [@"encrypted key block 2" dataUsingEncoding:NSUTF8StringEncoding]];
    [r2 setS: [@"signature block 2" dataUsingEncoding:NSUTF8StringEncoding]];
    [r2 setD: [@"encrypted secrets 2" dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableArray* r = [NSMutableArray arrayWithCapacity:2];
    [r addObject:r1];
    [r addObject:r2];
    
    Sender* s = [[Sender alloc] init];
    [s setI: [@"serialized hashed identity" dataUsingEncoding:NSUTF8StringEncoding]];
    [s setD: [@"device identifier" dataUsingEncoding:NSUTF8StringEncoding]];
    
    Message* m = [[Message alloc] init];
    [m setV: 3];
    [m setS: s];
    [m setI: [@"init vector" dataUsingEncoding:NSUTF8StringEncoding]];
    [m setL: YES];
    [m setA: [@"app" dataUsingEncoding:NSUTF8StringEncoding]];
    [m setR: r];
    [m setD: [@"encrypted data" dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSData* bson = [BSONEncoder encodeMessage:m];
    STAssertNotNil(bson, @"BSON should not be nil");
    
    Message* m2 = [BSONEncoder decodeMessage:bson];
    
    STAssertTrue(m.v == m2.v, @"Version doesn't match");
    STAssertTrue([m.s.i isEqualToData: m2.s.i], @"Sender identity doesn't match");
    STAssertTrue([m.s.d isEqualToData: m2.s.d], @"Sender device doesn't match");
    STAssertTrue([m.i isEqualToData: m2.i], @"Init vector doesn't match");
    STAssertTrue(m.l == m2.l, @"Blind doesn't match");
    STAssertTrue([m.a isEqualToData: m2.a], @"App doesn't match");
    STAssertTrue([m.r count] == [m2.r count], @"Number of recipients doesn't match");
    for (int i=0; i<[m.r count]; i++) {
        Recipient* r = [m.r objectAtIndex:i];
        Recipient* r2 = [m2.r objectAtIndex:i];
        
        STAssertTrue([r.i isEqualToData: r2.i], @"Recipient identity doesn't match");       
        STAssertTrue([r.k isEqualToData: r2.k], @"Recipient key block doesn't match");       
        STAssertTrue([r.s isEqualToData: r2.s], @"Recipient signature block doesn't match");       
        STAssertTrue([r.d isEqualToData: r2.d], @"Recipient secrets don't match");       
    }
    STAssertTrue([m.d isEqualToData: m2.d], @"Encrypted data doesn't match");
    
}

@end
