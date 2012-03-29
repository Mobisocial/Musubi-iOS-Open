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
#import "NSData+Crypto.h"

#import "IBEncryptionScheme.h"
#import "BSONEncoder.h"

#import "PersistentModelStore.h"
#import "MOutgoingSecret.h"
#import "MEncodedMessage.h"
#import "MIdentity.h"

#import "Message.h"
#import "Sender.h"
#import "Recipient.h"
#import "Secret.h"
#import "OutgoingMessage.h"

@implementation MessageEncoder

@synthesize transportDataProvider, encryptionScheme, signatureScheme;

- (id)initWithTransportDataProvider:(id<TransportDataProvider>)tdp {
    self = [super init];
    if (self) {
        [self setTransportDataProvider: tdp];
        [self setEncryptionScheme: [tdp encryptionScheme]];
        [self setSignatureScheme: [tdp signatureScheme]];
        deviceName = [tdp deviceName];
    }
    return self;
}

- (NSData*) computeFullSignatureForRecipients: (NSArray*) rcpts hash: (NSData*) h app: (NSData*) a blind: (BOOL) b {
    
    NSMutableData* sigData = [NSMutableData dataWithData: h];
    [sigData appendData: a];
    [sigData appendBytes:&b length:1];
    if (!b) {
        for (IBEncryptionIdentity* ident in rcpts) {
            [sigData appendData: ident.key];
        }
    }
    
    return [sigData sha256Digest];
}

- (MOutgoingSecret *)outgoingSecretFrom:(MIdentity *)from to:(MIdentity *)to fromIdent:(IBEncryptionIdentity *)me toIdent:(IBEncryptionIdentity *)you {
    
    IBEncryptionConversationKey* ck = [encryptionScheme randomConversationKeyWithIdentity:you];
    
    uint64_t deviceNameBigEndian = CFSwapInt64HostToBig((uint64_t) deviceName);    
    NSMutableData* hashData = [NSMutableData dataWithData: ck.encrypted];
    [hashData appendBytes:&deviceNameBigEndian length:sizeof(deviceNameBigEndian)];
    NSData* hash = [hashData sha256Digest];
    
    MOutgoingSecret* os = [transportDataProvider lookupOutgoingSecretFrom:from to:to myIdentity:me otherIdentity:you];
    if (os != nil) {
        return os;
    }
    
    os = (MOutgoingSecret*)[[transportDataProvider store] createEntity:@"OutgoingSecret"];
    [os setMyIdentity: from];
    [os setOtherIdentity: to];
    [os setKey: [ck raw]];
    [os setEncryptedKey: [ck encrypted]];
    [os setEncryptionPeriod: [you temporalFrame]];
    [os setSignature: [signatureScheme signHash:hash withUserKey:[transportDataProvider signatureKeyFrom:from myIdentity:me] andIdentity:me]];
    
    [transportDataProvider insertOutgoingSecret:os myIdentity:me otherIdentity:you];
    return os;
}

- (uint64_t) assignSequenceNumberTo: (MIdentity*) to {
    uint64_t next = [to nextSequenceNumber];
    [transportDataProvider incrementSequenceNumberTo: to];
    return next;
}

- (MEncodedMessage *) encodeOutgoingMessage:(OutgoingMessage *)om {
    // create the IBE identity for the sender
    IBEncryptionIdentity* me = [[[IBEncryptionIdentity alloc] initWithAuthority:[om fromIdentity].type hashedKey:[om fromIdentity].principalHash temporalFrame:[transportDataProvider signatureTimeFrom:[om fromIdentity]]] autorelease];
    
    /* TODO: verify if principal was intentionaly left out here. It crashes the refetch when signature is missing.
    IBEncryptionIdentity* me = [[[IBEncryptionIdentity alloc] initWithAuthority:[om fromIdentity].type hashedKey:[om fromIdentity].principalHash temporalFrame:[transportDataProvider signatureTimeFrom:[om fromIdentity]]] autorelease];
    IBEncryptionIdentity* me = nil;
    if ([om fromIdentity].principal != nil) {
        me = [[[IBEncryptionIdentity alloc] initWithAuthority:[om fromIdentity].type principal:[om fromIdentity].principal temporalFrame:[transportDataProvider signatureTimeFrom:[om fromIdentity]]] autorelease];        
    } else {
        me = [[[IBEncryptionIdentity alloc] initWithAuthority:[om fromIdentity].type hashedKey:[om fromIdentity].principalHash temporalFrame:[transportDataProvider signatureTimeFrom:[om fromIdentity]]] autorelease];        
    }*/

    // create an array of IBE identities for the recipients
    NSMutableArray* rcptIdentities = [NSMutableArray arrayWithCapacity:[[om recipients] count]];
    for (MIdentity* mRcpt in [om recipients]) {
        IBEncryptionIdentity* rcptIdent = [[[IBEncryptionIdentity alloc] initWithAuthority:mRcpt.type hashedKey:mRcpt.principalHash temporalFrame:[transportDataProvider encryptionTimeTo: mRcpt]] autorelease];
        [rcptIdentities addObject:rcptIdent];
    }
    
    // Use the identities and the rest of the message to calculate the signature hash
    assert([[om hash] isEqualToData: [[om data] sha256Digest]]);
    NSData* hash = [self computeFullSignatureForRecipients:rcptIdentities hash:[om hash] app:[om app] blind:[om blind]];
    
    // Generate a random key for the message
    NSData* messageKey = [NSData generateSecureRandomKeyOf:16];
    NSData* iv = [NSData generateSecureRandomKeyOf:16];
    
    NSMutableDictionary* seqNumbers = [NSMutableDictionary dictionaryWithCapacity:[[om recipients] count]];

    // Build the array of recipients (with secrets)
    NSMutableArray* recipients = [NSMutableArray arrayWithCapacity:[[om recipients] count]];
    int i = 0;
    uint64_t mySeqNumber = -1;
    for (MIdentity* mRcpt in [om recipients]) {
        IBEncryptionIdentity* rcptIdent = [rcptIdentities objectAtIndex:i++];
        
        MOutgoingSecret* os = [self outgoingSecretFrom:om.fromIdentity to:mRcpt fromIdent:me toIdent:rcptIdent];
        uint64_t seqNumber = [self assignSequenceNumberTo:mRcpt];
        
        Secret* s = [[[Secret alloc] init] autorelease];
        [s setH: hash];
        [s setK: messageKey];
        [s setQ: seqNumber];
        
        Recipient* rcpt = [[[Recipient alloc] init] autorelease];
        [rcpt setI: [rcptIdent key]];
        [rcpt setK: os.encryptedKey];
        [rcpt setS: os.signature];
        [rcpt setD: [[BSONEncoder encodeSecret:s] encryptWithAES128CBCZeroPaddedWithKey:[os key] andIV:iv]];
        
        [recipients addObject:rcpt];
        [seqNumbers setObject:[NSNumber numberWithLongLong:seqNumber] forKey:mRcpt.principalHash];
        
        if ([transportDataProvider isMe:rcptIdent]) {
            mySeqNumber = seqNumber;
        }
    }
    // Sender
    uint64_t deviceNameBigEndian = CFSwapInt64HostToBig(deviceName);
    Sender* sender = [[[Sender alloc] init] autorelease];
    [sender setI: [me key]];
    [sender setD: [NSData dataWithBytes:&deviceNameBigEndian length:sizeof(deviceNameBigEndian)]];

    // Message protocol format object
    Message* m = [[[Message alloc] init] autorelease];
    [m setV: 0]; //version
    [m setI: iv];
    [m setA: om.app];
    [m setL: om.blind];
    [m setS: sender];
    [m setR: recipients];
    [m setD: [[om data] encryptWithAES128CBCPKCS7WithKey:messageKey andIV:iv]];
    
    MEncodedMessage* encoded = (MEncodedMessage*)[[transportDataProvider store] createEntity:@"EncodedMessage"];
    [encoded setFromIdentity: [om fromIdentity]];
    [encoded setFromDevice: [transportDataProvider addDeviceWithName:deviceName forIdentity:om.fromIdentity]];
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
