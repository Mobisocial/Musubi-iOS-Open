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
//  TransientTransportDataProvider.m
//  Musubi
//
//  Created by Willem Bult on 2/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TransientTransportDataProvider.h"
#import "PersistentModelStore.h"
#import "NSData+Crypto.h"

@implementation DefaultBlackListProvider
- (BOOL)isBlackListed:(IBEncryptionIdentity *)identity {
    return FALSE;
}
@end

@implementation DefaultSignatureController
- (long)signingTimeForIdentity:(IBEncryptionIdentity *)hid {
    return *(long*)hid.hashed.bytes;
}
- (BOOL)hasSignatureKey:(IBEncryptionIdentity *)hid {
    return YES;
}
@end

@implementation DefaultEncryptionController
- (long)encryptionTimeForIdentity:(IBEncryptionIdentity *)hid {
    return *(long*)hid.hashed.bytes;
}
- (BOOL)hasEncryptionKey:(IBEncryptionIdentity *)hid {
    return YES;
}
@end

@implementation TransientTransportDataProvider

@synthesize blacklistProvider, signatureController, encryptionController, store, encryptionScheme,signatureScheme,myIdentity,deviceName,identities,identityLookup,devices,deviceLookup,encodedMessages,encodedMessageLookup,incomingSecrets,outgoingSecrets,missingSequenceNumbers;

- (id)initWithEncryptionScheme:(IBEncryptionScheme *)es signatureScheme:(IBSignatureScheme *)ss identity:(IBEncryptionIdentity *)me blacklistProvicer:(id<BlackListProvider>)blacklist signatureController:(id<SignatureController>)sigController encryptionController:(id<EncryptionController>)encController {
    
    self = [super init];
    if (self != nil) {
        [self setStore: [[PersistentModelStore alloc] initWithCoordinator:[PersistentModelStore coordinatorWithName:@"TestStore1"]]];
        
        [self setEncryptionScheme: es];
        [self setSignatureScheme: ss];
        [self setMyIdentity: me];
        
        [self setDeviceName: random()];
        
        [self setIdentities: [[NSMutableDictionary alloc] init]];
        [self setIdentityLookup: [[NSMutableDictionary alloc] init]];
        [self setDevices: [[NSMutableDictionary alloc] init]];
        [self setDeviceLookup: [[NSMutableDictionary alloc] init]];
        [self setEncodedMessages: [[NSMutableDictionary alloc] init]];
        [self setEncodedMessageLookup: [[NSMutableDictionary alloc] init]];
        [self setIncomingSecrets: [[NSMutableDictionary alloc] init]];
        [self setOutgoingSecrets: [[NSMutableDictionary alloc] init]];
        [self setMissingSequenceNumbers: [[NSMutableDictionary alloc] init]];
        
        MIdentity* ident = [store createIdentity];
        [ident setId: [identities count]];
        [ident setClaimed: YES];
        [ident setOwned: YES];
        [ident setType: kIBEncryptionIdentityAuthorityEmail];
        [ident setPrincipal: me.principal];
        [ident setPrincipalHash: me.hashed];
        [ident setPrincipalShortHash: *(long*)me.hashed.bytes];
        
        [identities setObject:ident forKey:[NSNumber numberWithLong: ident.id]];
        [identityLookup setObject:ident forKey:[NSArray arrayWithObjects:ident.principalHash, nil]];
        
        [self addDeviceWithName:[self deviceName] forIdentity:ident];
        
        if (blacklist != nil) {
            [self setBlacklistProvider: blacklist];
        } else {
            [self setBlacklistProvider: [[DefaultBlackListProvider alloc] init]];
        }

        if (sigController != nil) {
            [self setSignatureController: sigController];
        } else {
            [self setSignatureController: [[DefaultSignatureController alloc] init]];
        }

        if (encController != nil) {
            [self setEncryptionController: encController];
        } else {
            [self setEncryptionController: [[DefaultEncryptionController alloc] init]];
        }

    }

    return self;
}

- (IBEncryptionUserKey *)signatureKeyFrom:(MIdentity *)from myIdentity:(IBEncryptionIdentity *)me {
    if (![self.signatureController hasSignatureKey:me])
        @throw [NSException exceptionWithName:@"Missing Signature Key" reason:@"Signature key not found for identity" userInfo:nil];
    
    return [self.signatureScheme userKeyWithIdentity:me];
}

- (IBEncryptionUserKey *)encryptionKeyTo:(MIdentity *)to myIdentity:(IBEncryptionIdentity *)me {
    if (![self.encryptionController hasEncryptionKey:me])
        @throw [NSException exceptionWithName:@"Missing Encryption Key" reason:@"Encryption key not found for identity" userInfo:nil];
    
    return [self.encryptionScheme userKeyWithIdentity:me];
}

- (long)signatureTimeFrom:(MIdentity *)from {
    IBEncryptionIdentity* ibeIdent = [[IBEncryptionIdentity alloc] initWithAuthority:from.type hashedKey:from.principalHash temporalFrame:0];
    return [self.signatureController signingTimeForIdentity:ibeIdent];
}

- (long)encryptionTimeTo:(MIdentity *)to {
    IBEncryptionIdentity* ibeIdent = [[IBEncryptionIdentity alloc] initWithAuthority:to.type hashedKey:to.principalHash temporalFrame:0];
    return [self.encryptionController encryptionTimeForIdentity:ibeIdent];
}

- (MOutgoingSecret *)lookupOutgoingSecretFrom:(MIdentity *)from to:(MIdentity *)to myIdentity:(IBEncryptionIdentity *)me otherIdentity:(IBEncryptionIdentity *)other {
    NSArray* key = [NSArray arrayWithObjects: [NSNumber numberWithLong: from.id], [NSNumber numberWithLong: to.id], [NSNumber numberWithLong: me.temporalFrame], [NSNumber numberWithLong: other.temporalFrame], nil];
    
    return [outgoingSecrets objectForKey:key];
}

- (void)insertOutgoingSecret:(MOutgoingSecret *)os myIdentity:(IBEncryptionIdentity *)me otherIdentity:(IBEncryptionIdentity *)other {
    NSArray* key = [NSArray arrayWithObjects: [NSNumber numberWithLong: os.myIdentityId], [NSNumber numberWithLong: os.otherIdentityId], [NSNumber numberWithLong: me.temporalFrame], [NSNumber numberWithLong: other.temporalFrame], nil];
    
    [outgoingSecrets setObject:os forKey:key];
}

- (MIncomingSecret *)lookupIncomingSecretFrom:(MIdentity *)from onDevice:(MDevice *)device to:(MIdentity *)to withSignature:(NSData *)signature otherIdentity:(IBEncryptionIdentity *)other myIdentity:(IBEncryptionIdentity *)me {
    NSArray* key = [NSArray arrayWithObjects:[NSNumber numberWithLong: device.id], [NSNumber numberWithLong:to.id], signature, me, nil];
    
    return [incomingSecrets objectForKey:key];
}

- (void)insertIncomingSecret:(MIncomingSecret *)is otherIdentity:(IBEncryptionIdentity *)other myIdentity:(IBEncryptionIdentity *)me {
    NSArray* key = [NSArray arrayWithObjects:[NSNumber numberWithLong:is.deviceId], [NSNumber numberWithLong:is.myIdentityId], is.signature, me, nil];
    
    [incomingSecrets setObject:is forKey:key];
}

- (void)incrementSequenceNumberTo:(MIdentity *)to {
    MIdentity* ident = [identities objectForKey:[NSNumber numberWithLong:to.id]];
    ident.nextSequenceNumber++;
}

- (void)receivedSequenceNumber:(long)sequenceNumber from:(MDevice *)device {
    NSArray* key = [NSArray arrayWithObjects: [NSNumber numberWithLong:device.identityId], [NSNumber numberWithLong:device.deviceName], nil];
    long maxSequenceNumber = ((MDevice*)[devices objectForKey:[NSNumber numberWithLong:device.id]]).maxSequenceNumber;
    if (sequenceNumber > maxSequenceNumber) {
        [((MDevice*)[devices objectForKey:[NSNumber numberWithLong:device.id]]) setMaxSequenceNumber:sequenceNumber];
    }
   
    NSMutableSet* missing = [missingSequenceNumbers objectForKey:key];
    if (missing != nil)
        [missing removeObject: [NSNumber numberWithLong: sequenceNumber]];
    
    if (sequenceNumber > maxSequenceNumber + 1) {
        if (missing == nil) {
            missing = [[NSMutableSet alloc] init];
            [missingSequenceNumbers setObject:missing forKey:key];
        }
        for (long q = maxSequenceNumber + 1; q < sequenceNumber; ++q) {
            [missing addObject: [NSNumber numberWithLong: q]];
        }
    }
}

- (BOOL)haveHash:(NSData*)hash {
    MEncodedMessage* encoded = [encodedMessageLookup objectForKey:hash];
    return (encoded != nil);
}

- (void)storeSequenceNumbers:(NSDictionary *)seqNumbers forEncodedMessage:(MEncodedMessage *)encoded {
    /*
    sequence_numbers.forEachEntry(new TLongLongProcedure() {
        public boolean execute(long identityId, long sequenceNumber) {
            encodedMessageForPersonBySequenceNumber.put(Pair.with(identityId, sequenceNumber), encoded.id_);
            return true;
        }
    });
    */
}

- (BOOL)isBlackListed:(MIdentity *)ident {
    return [blacklistProvider isBlackListed:[[IBEncryptionIdentity alloc] initWithAuthority:ident.type hashedKey:ident.principalHash temporalFrame:0]];
}

- (BOOL)isMe:(IBEncryptionIdentity *)ident {
    return [ident equalsStable: myIdentity];  
}

- (MIdentity *)addClaimedIdentity:(IBEncryptionIdentity *)hid {
    NSArray* lookupKey = [NSArray arrayWithObjects:[NSNumber numberWithInt: [hid authority]], [hid hashed], nil];
    
    MIdentity* ident = [identityLookup objectForKey:lookupKey];
    if (ident != nil)
        return ident;
    
    ident = [store createIdentity];
    [ident setId: [identities count] + 1];
    [ident setClaimed: YES];
    [ident setOwned: NO];
    [ident setType: kIBEncryptionIdentityAuthorityEmail];
    [ident setPrincipalHash: [hid hashed]];
    [ident setPrincipalShortHash: *(long*)hid.hashed.bytes];
    
    [identities setObject:ident forKey:[NSNumber numberWithLong: ident.id]];
    [identityLookup setObject:ident forKey:lookupKey];
    return ident;
}

- (MIdentity *)addUnclaimedIdentity:(IBEncryptionIdentity *)hid {
    NSArray* lookupKey = [NSArray arrayWithObjects:[NSNumber numberWithInt: [hid authority]], [hid hashed], nil];
    
    MIdentity* ident = [identityLookup objectForKey:lookupKey];
    if (ident != nil)
        return ident;
    
    ident = [store createIdentity];
    [ident setId: [identities count] + 1];
    [ident setClaimed: NO];
    [ident setOwned: NO];
    [ident setType: kIBEncryptionIdentityAuthorityEmail];
    [ident setPrincipalHash: [hid hashed]];
    [ident setPrincipalShortHash: *(long*)hid.hashed.bytes];
    
    [identities setObject:ident forKey:[NSNumber numberWithLong: ident.id]];
    [identityLookup setObject:ident forKey:lookupKey];
    return ident;
}

- (MDevice *)addDeviceWithName:(long)devName forIdentity:(MIdentity *)ident {
    NSArray* lookupKey = [NSArray arrayWithObjects:[NSNumber numberWithLong: ident.id], [NSNumber numberWithLong:devName], nil];

    MDevice* d = [deviceLookup objectForKey:lookupKey];
    if(d != nil)
        return d;
    
    d = [store createDevice];
    [d setId: [devices count] + 1];
    [d setIdentityId: [ident id]];
    [d setDeviceName: devName];
    [d setMaxSequenceNumber: -1];
    
    [devices setObject:d forKey:[NSNumber numberWithLong: d.id]];
    [deviceLookup setObject:d forKey:lookupKey];
    
    return d;
}

- (void)updateEncodedMetadata:(MEncodedMessage *)encoded {
    [encodedMessageLookup setObject:encoded forKey:[encoded.encoded sha256Digest]];
}

- (void)insertEncodedMessage:(MEncodedMessage *)encoded forOutgoingMessage:(OutgoingMessage *)om {
    
    NSLog(@"Inserting message with message hash:\n%@\nand hash:\n%@", [encoded messageHash], [encoded.encoded sha256Digest]);

    [encodedMessages setObject:encoded forKey:[NSNumber numberWithLong: encoded.id]];
    [encodedMessageLookup setObject:encoded forKey:[encoded.encoded sha256Digest]];
}

- (MEncodedMessage *)insertEncodedMessageData:(NSData *)data {
    MEncodedMessage* encodedMessage = [store createEncodedMessage];
    [encodedMessage setEncoded: data];
    [encodedMessages setObject:encodedMessage forKey:[NSNumber numberWithLong: encodedMessage.id]];
    return encodedMessage;
}
@end
