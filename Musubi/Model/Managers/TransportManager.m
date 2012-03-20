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

@synthesize store, encryptionScheme, signatureScheme, deviceName, identityManager, signatureUserKeyManager, encryptionUserKeyManager, outgoingSecretManager;

- (id)initWithStore:(PersistentModelStore *)s encryptionScheme:(IBEncryptionScheme *)es signatureScheme:(IBSignatureScheme *)ss deviceName:(long)devName {
    self = [super init];
    
    if (self != nil) {
        [self setStore: s];
        [self setEncryptionScheme: es];
        [self setSignatureScheme: ss];
        [self setDeviceName: devName];
        
        [self setIdentityManager: [[[IdentityManager alloc] initWithStore: store] autorelease]];
        [self setSignatureUserKeyManager: [[[UserKeyManager alloc] initWithStore:store encryptionScheme:es signatureScheme:ss] autorelease]];
        [self setEncryptionUserKeyManager: [[[EncryptionUserKeyManager alloc] initWithStore:store encryptionScheme:es] autorelease]];
        [self setOutgoingSecretManager: [[[OutgoingSecretManager alloc] initWithStore:store] autorelease]];
    }
    
    return self;
}

- (NSArray*) query: (NSString*) entityName predicate: (NSPredicate*) predicate {
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:[store context]];
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entity];
    [request setPredicate:predicate];
    
    NSError *error = nil;
    return [[store context] executeFetchRequest:request error:&error];
}

- (NSManagedObject*) queryFirst: (NSString*) entityName predicate: (NSPredicate*) predicate {
    NSArray* results = [self query:entityName predicate:predicate];
    if (results.count > 0) {
        return [results objectAtIndex:0];
    } else {
        return nil;
    }
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
    MSignatureUserKey* key = (MSignatureUserKey*)[self queryFirst:@"SignatureUserKey" predicate:[NSPredicate predicateWithFormat:@"identity = %@ AND period = %ld", from, me.temporalFrame]];
    return key ? [[[IBEncryptionUserKey alloc] initWithRaw: key.key] autorelease] : nil;
}

- (IBEncryptionUserKey *)encryptionKeyTo:(MIdentity *)to myIdentity:(IBEncryptionIdentity *)me {
    MEncryptionUserKey* key = (MEncryptionUserKey*)[self queryFirst:@"EncryptionUserKey" predicate:[NSPredicate predicateWithFormat:@"identity = %@ AND period = %ld", to, me.temporalFrame]];
    return key ? [[[IBEncryptionUserKey alloc] initWithRaw: key.key] autorelease] : nil;
}

- (MOutgoingSecret *)lookupOutgoingSecretFrom:(MIdentity *)from to:(MIdentity *)to myIdentity:(IBEncryptionIdentity *)me otherIdentity:(IBEncryptionIdentity *)other {
    return (MOutgoingSecret*)[self queryFirst:@"OutgoingSecret" predicate:[NSPredicate predicateWithFormat:@"myIdentityId = %ld AND otherIdentityId = %ld AND encryptionPeriod = %ld AND signaturePeriod = %ld", from.id, to.id, me.temporalFrame, other.temporalFrame]];
}

- (void)insertOutgoingSecret:(MOutgoingSecret *)os myIdentity:(IBEncryptionIdentity *)me otherIdentity:(IBEncryptionIdentity *)other {
    //TODO: Seriously, nothing?
    //[[store context] save:NULL];
    [os setId: [[os objectID] hash]];
}

- (MIncomingSecret *)lookupIncomingSecretFrom:(MIdentity *)from onDevice:(MDevice *)device to:(MIdentity *)to withSignature:(NSData *)signature otherIdentity:(IBEncryptionIdentity *)other myIdentity:(IBEncryptionIdentity *)me {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"myIdentityId = %ld AND otherIdentityId = %ld AND encryptionPeriod = %ld AND signaturePeriod = %ld AND deviceId", from.id, to.id, other.temporalFrame, me.temporalFrame, device.id];
    
    NSArray* results = [self query:@"IncomingSecret" predicate:predicate];
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
    //[[store context] save:NULL];
    [is setId: [[is objectID] hash]];
}

- (void)incrementSequenceNumberTo:(MIdentity *)to {
    [identityManager incrementSequenceNumberTo: to];
}

- (void)receivedSequenceNumber:(long)sequenceNumber from:(MDevice *)device {
    MMissingMessage* mm = (MMissingMessage*) [self queryFirst:@"MissingMessage" predicate:[NSPredicate predicateWithFormat:@"device = %@ AND sequenceNumber = %ld", device, sequenceNumber]];
    if (mm) {
        [[store context] deleteObject:mm];
    }
}

- (void)storeSequenceNumbers:(NSDictionary *)seqNumbers forEncodedMessage:(MEncodedMessage *)encoded {
    NSEnumerator* keyEnum = [seqNumbers keyEnumerator];
    while (true) {
        NSNumber* rcptId = (NSNumber*) [keyEnum nextObject];
        if (rcptId == nil)
            break;
        
        MIdentity* ident = (MIdentity*)[self queryFirst:@"Identity" predicate:[NSPredicate predicateWithFormat:@"id=%ld", rcptId.longValue]];
        
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
    NSArray* results = [self query:@"Identity" predicate:[NSPredicate predicateWithFormat:@"type = %d AND principalShortHash = %ld AND principalHash = %@ AND owned = 1", ident.authority, *(long*)ident.hashed.bytes, ident.hashed]];
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
    
    MDevice* dev = (MDevice*) [self queryFirst:@"Device" predicate:[NSPredicate predicateWithFormat:@"identityId = %ld AND deviceName = %ld", ident.id, devName]];
    
    if (dev == nil) {
        dev = (MDevice*) [NSEntityDescription insertNewObjectForEntityForName:@"Device" inManagedObjectContext: [store context]];
        [dev setDeviceName: devName];
        [dev setIdentityId: ident.id];
        [dev setMaxSequenceNumber: 0];
    }
    
    return dev;
}

- (void)insertEncodedMessage:(MEncodedMessage *)encoded forOutgoingMessage:(OutgoingMessage *)om {
    //[[store context] save: NULL];
}

- (void)updateEncodedMetadata:(MEncodedMessage *)encoded {
    //[[store context] save: NULL];
}

- (BOOL)haveHash:(NSData *)hash {
    
    //TODO: actual implementation
    return NO;
}


@end
