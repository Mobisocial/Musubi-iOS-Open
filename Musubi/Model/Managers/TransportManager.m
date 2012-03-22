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
//  TransportManager.m
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TransportManager.h"

@implementation TransportManager

@synthesize store, encryptionScheme, signatureScheme, deviceName, identityManager;

- (id)initWithStore:(PersistentModelStore *)s encryptionScheme:(IBEncryptionScheme *)es signatureScheme:(IBSignatureScheme *)ss deviceName:(long)devName {
    self = [super init];
    
    if (self != nil) {
        [self setStore: s];
        [self setEncryptionScheme: es];
        [self setSignatureScheme: ss];
        [self setDeviceName: devName];
        
        [self setIdentityManager: [[[IdentityManager alloc] initWithStore: store] autorelease]];
    }
    
    return self;
}

- (void)setStore:(PersistentModelStore *)s {
    [store release];
    store = [s retain];
    
    [identityManager setStore:s];
}

- (long)signatureTimeFrom:(MIdentity *)from {
    //TODO: consider revocation/online offline status, etc
    return [identityManager computeTemporalFrameFromHash: from.principalHash];
}

- (long)encryptionTimeTo:(MIdentity *)to {
    //TODO: consider revocation/online offline status, etc
    return [identityManager computeTemporalFrameFromHash: to.principalHash];
}

-  (IBEncryptionUserKey *)signatureKeyFrom:(MIdentity *)from myIdentity:(IBEncryptionIdentity *)me {
    MSignatureUserKey* key = (MSignatureUserKey*)[store queryFirst:[NSPredicate predicateWithFormat:@"identity = %@ AND period = %ld", from, me.temporalFrame] onEntity:@"SignatureUserKey"];
    return key ? [[[IBEncryptionUserKey alloc] initWithRaw: key.key] autorelease] : nil;
}

- (IBEncryptionUserKey *)encryptionKeyTo:(MIdentity *)to myIdentity:(IBEncryptionIdentity *)me {
    MEncryptionUserKey* key = (MEncryptionUserKey*)[store queryFirst:[NSPredicate predicateWithFormat:@"identity = %@ AND period = %ld", to, me.temporalFrame] onEntity:@"EncryptionUserKey"];
    return key ? [[[IBEncryptionUserKey alloc] initWithRaw: key.key] autorelease] : nil;
}

- (MOutgoingSecret *)lookupOutgoingSecretFrom:(MIdentity *)from to:(MIdentity *)to myIdentity:(IBEncryptionIdentity *)me otherIdentity:(IBEncryptionIdentity *)other {
    return (MOutgoingSecret*)[store queryFirst:[NSPredicate predicateWithFormat:@"myIdentity = %@ AND otherIdentity = %@ AND encryptionPeriod = %ld AND signaturePeriod = %ld", from, to, me.temporalFrame, other.temporalFrame] onEntity:@"OutgoingSecret"];
}

- (void)insertOutgoingSecret:(MOutgoingSecret *)os myIdentity:(IBEncryptionIdentity *)me otherIdentity:(IBEncryptionIdentity *)other {
    //TODO: Seriously, nothing?
    [[store context] save:NULL];
}

- (MIncomingSecret *)lookupIncomingSecretFrom:(MIdentity *)from onDevice:(MDevice *)device to:(MIdentity *)to withSignature:(NSData *)signature otherIdentity:(IBEncryptionIdentity *)other myIdentity:(IBEncryptionIdentity *)me {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"myIdentity = %@ AND otherIdentity = %@ AND encryptionPeriod = %ld AND signaturePeriod = %ld AND device = %@", from, to, other.temporalFrame, me.temporalFrame, device];
    
    NSArray* results = [store query:predicate onEntity:@"IncomingSecret"];
    for (int i=0; i<results.count; i++) {
        MIncomingSecret* secret = (MIncomingSecret*) [results objectAtIndex:i];
        
        // It's possible to have different signatures on the same set of parameters; skip
        if (![secret.signature isEqualToData:signature])
            continue;
        
        return secret;
    }
    
    return nil;
}

- (void)insertIncomingSecret:(MIncomingSecret *)is otherIdentity:(IBEncryptionIdentity *)other myIdentity:(IBEncryptionIdentity *)me {
    //TODO: Seriously, nothing?
    [[store context] save:NULL];
}

- (void)incrementSequenceNumberTo:(MIdentity *)to {
    [identityManager incrementSequenceNumberTo: to];
}

- (void)receivedSequenceNumber:(long)sequenceNumber from:(MDevice *)device {
    MMissingMessage* mm = (MMissingMessage*) [store queryFirst:[NSPredicate predicateWithFormat:@"device = %@ AND sequenceNumber = %ld", device, sequenceNumber] onEntity:@"MissingMessage"];
    if (mm) {
        [[store context] deleteObject:mm];
    }
}

- (void)storeSequenceNumbers:(NSDictionary *)seqNumbers forEncodedMessage:(MEncodedMessage *)encoded {
    NSEnumerator* keyEnum = [seqNumbers keyEnumerator];
    while (true) {
        NSData* rcptHash = (NSData*) [keyEnum nextObject];
        if (rcptHash == nil)
            break;
        
        MIdentity* ident = (MIdentity*)[store queryFirst:[NSPredicate predicateWithFormat:@"principalHash=%@", rcptHash] onEntity:@"Identity"];
        
        MSequenceNumber* seqNumber = (MSequenceNumber*) [NSEntityDescription insertNewObjectForEntityForName:@"SequenceNumber" inManagedObjectContext: [store context]];
        [seqNumber setRecipient:ident];
        [seqNumber setSequenceNumber: [(NSNumber*)[seqNumbers objectForKey:ident] longValue]];
        [seqNumber setEncodedMessage: encoded];
    }
}

- (BOOL)isBlackListed:(MIdentity *)ident {
    return FALSE;
}

- (BOOL)isMe:(IBEncryptionIdentity *)ident {
    NSArray* results = [store query:[NSPredicate predicateWithFormat:@"type = %d AND principalShortHash = %ld AND principalHash = %@ AND owned = 1", ident.authority, *(long*)ident.hashed.bytes, ident.hashed] onEntity:@"Identity"];
    return (results.count > 0);
}

- (MIdentity*) addClaimedIdentity:(IBEncryptionIdentity *)ident {
    MIdentity* mIdent = [identityManager identityForIBEncryptionIdentity:ident];
    
    if (mIdent != nil) {
        if (!mIdent.claimed) {
            [mIdent setClaimed: YES];
            [identityManager updateIdentity:mIdent];
        }
    } else {
        mIdent = (MIdentity*)[identityManager create];
        [mIdent setClaimed: YES];
        [mIdent setPrincipalHash: ident.hashed];
        [mIdent setPrincipalShortHash: *(long*)ident.hashed.bytes];
        [mIdent setType: ident.authority];        
        [identityManager createIdentity:mIdent];    
    }
    
    return mIdent;
}

- (MIdentity *)addUnclaimedIdentity:(IBEncryptionIdentity *)ident {
    MIdentity* mIdent = [identityManager identityForIBEncryptionIdentity:ident];
  
    if (mIdent == nil) {
        [mIdent setClaimed: NO];
        [mIdent setPrincipalHash: ident.hashed];
        [mIdent setPrincipalShortHash: *(long*)ident.hashed.bytes];
        [mIdent setType: ident.authority];
        
        [identityManager createIdentity:mIdent];    
    }
    
    return mIdent;
}

- (MDevice *)addDeviceWithName:(long)devName forIdentity:(MIdentity *)ident {
    
    MDevice* dev = (MDevice*) [store queryFirst:[NSPredicate predicateWithFormat:@"identity = %@ AND deviceName = %ld", ident, devName] onEntity:@"Device"];
    
    if (dev == nil) {
        dev = (MDevice*) [NSEntityDescription insertNewObjectForEntityForName:@"Device" inManagedObjectContext: [store context]];
        [dev setDeviceName: devName];
        [dev setIdentity: ident];
        [dev setMaxSequenceNumber: 0];
    }
    
    return dev;
}

- (void)insertEncodedMessage:(MEncodedMessage *)encoded forOutgoingMessage:(OutgoingMessage *)om {
    [[store context] save: NULL];
}

- (void)updateEncodedMetadata:(MEncodedMessage *)encoded {
    [[store context] save: NULL];
}

- (BOOL)haveHash:(NSData *)hash {
    
    //TODO: actual implementation
    return NO;
}


@end
