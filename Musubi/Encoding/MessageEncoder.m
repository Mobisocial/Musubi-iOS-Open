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
//  MessageEncoder.m
//  Musubi
//
//  Created by Willem Bult on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MessageEncoder.h"
#import "Message.h"
#import "Sender.h"
#import "Recipient.h"
#import "Secret.h"
#import "NSData+Crypto.h"
#import "IBEncryptionScheme.h"
#import "BSONEncoder.h"

@implementation MessageEncoder

@synthesize transportDataProvider, encryptionScheme, signatureScheme;

- (id)initWithTransportDataProvider:(TransportDataProvider *)tdp {
    self = [super init];
    if (self) {
        [self setTransportDataProvider: tdp];
        deviceName = [tdp deviceName];
    }
    return self;
}

- (NSData*) computeFullSignatureForRecipients: (NSArray*) rcpts hash: (NSData*) h app: (NSData*) a blind: (BOOL) b {
    
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, [h bytes], [h length]);
    CC_SHA256_Update(&ctx, [a bytes], [a length]);
    CC_SHA256_Update(&ctx, &b, sizeof(b));
    for (IBEncryptionIdentity* ident in rcpts) {
        NSData* key = [ident key];
        CC_SHA256_Update(&ctx, [key bytes], [key length]);
    }
    
    CC_SHA256_Final(digest, &ctx);
    return [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
}

- (MOutgoingSecret *)outgoingSecretFrom:(MIdentity *)from to:(MIdentity *)to fromIdent:(IBEncryptionIdentity *)me toIdent:(IBEncryptionIdentity *)you {
    
    IBEncryptionConversationKey* ck = [encryptionScheme randomConversationKeyWithIdentity:you];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256_CTX ctx;
    CC_SHA256_Init(&ctx);
    CC_SHA256_Update(&ctx, [[ck encrypted] bytes], [[ck encrypted] length]);
    CC_SHA256_Update(&ctx, &deviceName, sizeof(deviceName));
    CC_SHA256_Final(digest, &ctx);
    NSData* hash = [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
    
    MOutgoingSecret* os = [transportDataProvider lookupOutgoingSecretFrom: from to: to fromIdent: me toIdent: you];
    if (os != nil) {
        return os;
    }
    
    os = [[MOutgoingSecret alloc] init]; //TODO: create in DB
    [os setMyIdentityId: [from id]];
    [os setOtherIdentityId: [to id]];
    [os setKey: [ck raw]];
    [os setEncryptedKey: [ck encrypted]];
    [os setEncryptionPeriod: [you temporalFrame]];
    [os setSignature: [signatureScheme signHash:hash withUserKey:[transportDataProvider signatureKeyForIdentity:from andIBEIdentity:me] andIdentity:me]];
    
    [transportDataProvider insertOutgoingSecret: os from: me to: you];
    return os;
}

- (long) assignSequenceNumberTo: (MIdentity*) to {
    long next = [to nextSequenceNumber];
    [transportDataProvider incrementSequenceNumberTo: to];
    return next;
}

- (MEncodedMessage *) encodeOutgoingMessage:(OutgoingMessage *)om {
    // create the IBE identity for the sender
    IBEncryptionIdentity* me = [[IBEncryptionIdentity alloc] initWithAuthority:[om fromIdentity].type andHashedKey:[om fromIdentity].principalHash andTemporalFrame:[transportDataProvider signatureTimeForIdentity: [om fromIdentity]]];

    // create an array of IBE identities for the recipients
    NSMutableArray* rcptIdentities = [NSMutableArray arrayWithCapacity:[[om recipients] count]];
    for (MIdentity* mRcpt in [om recipients]) {
        IBEncryptionIdentity* rcptIdent = [[IBEncryptionIdentity alloc] initWithAuthority:mRcpt.type andHashedKey:mRcpt.principalHash andTemporalFrame:[transportDataProvider encryptionTimeForIdentity: mRcpt]];
        [rcptIdentities addObject:rcptIdent];
    }
    
    // Use the identities and the rest of the message to calculate the signature hash
    assert([[om hash] isEqualToData: [[om data] sha256Digest]]);
    NSData* hash = [self computeFullSignatureForRecipients:rcptIdentities hash:[om hash] app:[om app] blind:[om blind]];
    
    // Generate a random key for the message
    NSData* messageKey = [NSData generateSecureRandomKeyOf:16];
    NSData* iv = [NSData generateSecureRandomKeyOf:16];
    
    NSMutableDictionary* seqNumbers = [NSMutableDictionary dictionary];

    // Build the array of recipients (with secrets)
    NSMutableArray* recipients = [NSMutableArray arrayWithCapacity:[[om recipients] count]];
    int i = 0;
    long mySeqNumber = -1;
    for (MIdentity* mRcpt in [om recipients]) {
        IBEncryptionIdentity* rcptIdent = [rcptIdentities objectAtIndex:i++];
        
        MOutgoingSecret* os = [self outgoingSecretFrom:om.fromIdentity to:mRcpt fromIdent:me toIdent:rcptIdent];
        int seqNumber = [self assignSequenceNumberTo:mRcpt];
        
        Secret* s = [[Secret alloc] init];
        [s setH: hash];
        [s setK: messageKey];
        [s setQ: seqNumber]; 
        
        Recipient* rcpt = [[Recipient alloc] init];
        [rcpt setI: [rcptIdent key]];
        [rcpt setK: os.encryptedKey];
        [rcpt setS: os.signature];
        [rcpt setD: [[BSONEncoder encodeSecret:s] encryptWithAES128CBCZeroPaddedWithKey:[os key] andIV:iv]];
        
        [recipients addObject:rcpt];
        [seqNumbers setObject:[NSNumber numberWithLong:mRcpt.id] forKey:[NSNumber numberWithLong: seqNumber]];
        
        if ([transportDataProvider isMe:rcptIdent]) {
            mySeqNumber = seqNumber;
        }
    }

    // Sender
    Sender* sender = [[Sender alloc] init];
    [sender setI: [me key]];
    [sender setD: [NSData dataWithBytes:&deviceName length:sizeof(deviceName)]];

    // Message protocol format object
    Message* m = [[Message alloc] init];
    [m setV: 0]; //version
    [m setI: iv];
    [m setA: om.app];
    [m setL: om.blind];
    [m setS: sender];
    [m setR: recipients];
    [m setD: [[om data] encryptWithAES128CBCPKCS7WithKey:messageKey andIV:iv]];

    // The encoded message that contains everything for the wire
    MEncodedMessage* encoded = [[MEncodedMessage alloc] init]; // create in database?
    [encoded setFromIdentityId: [om fromIdentity].id];
    [encoded setFromDevice: [transportDataProvider addDevice: om.fromIdentity withName: deviceName].id];
    [encoded setMessageHash: hash];
    [encoded setProcessed: NO];
    [encoded setOutbound: YES];
    [encoded setSequenceNumber: mySeqNumber];
    [encoded setEncoded: [BSONEncoder encodeMessage:m]];
    
    // Track the message and sequence numbers in the TransportDataProvider
    [transportDataProvider insertEncodedMessage: encoded forOutgoingMessage: om];
    [transportDataProvider storeSequenceNumbers: seqNumbers forEncodedMessage: encoded];
    return encoded;
}

@end
