//
//  TransportDataProvider.h
//  Musubi
//
//  Created by Willem Bult on 2/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IBEncryptionScheme, IBSignatureScheme, IBEncryptionUserKey, IBSignatureUserKey, IBEncryptionIdentity;
@class PersistentModelStore, MIdentity, MOutgoingSecret, MIncomingSecret, MDevice, MEncodedMessage, OutgoingMessage;

@protocol TransportDataProvider

- (PersistentModelStore*) store;

/* IBE secrets */
- (IBEncryptionScheme*) encryptionScheme;
- (IBSignatureScheme*) signatureScheme;

- (IBSignatureUserKey*) signatureKeyFrom:(MIdentity *)from myIdentity: (IBEncryptionIdentity*) me;
- (IBEncryptionUserKey*) encryptionKeyTo:(MIdentity *)to myIdentity: (IBEncryptionIdentity*) me;

/* Compute times given an identity, might consult for revocation etc */
- (uint64_t) signatureTimeFrom: (MIdentity*) from;
- (uint64_t) encryptionTimeTo: (MIdentity*) to;

/* My one and only */
- (uint64_t) deviceName;

/* Channel secret management */
- (MOutgoingSecret *)lookupOutgoingSecretFrom:(MIdentity *)from to:(MIdentity *)to myIdentity:(IBEncryptionIdentity *)me otherIdentity:(IBEncryptionIdentity *)other;
- (void) insertOutgoingSecret: (MOutgoingSecret*) os myIdentity:(IBEncryptionIdentity*)me otherIdentity: (IBEncryptionIdentity*) other;
- (MIncomingSecret *)lookupIncomingSecretFrom:(MIdentity *)from onDevice: (MDevice*) device to:(MIdentity *)to withSignature: (NSData*) signature otherIdentity:(IBEncryptionIdentity *)other myIdentity:(IBEncryptionIdentity *)me;
- (void) insertIncomingSecret: (MIncomingSecret*) is otherIdentity: (IBEncryptionIdentity*) other myIdentity: (IBEncryptionIdentity*) me;

/* Sequence number manipulation */
- (void) incrementSequenceNumberTo: (MIdentity*) to;
- (void) receivedSequenceNumber: (uint64_t) sequenceNumber from: (MDevice*) device;
- (BOOL) haveHash: (NSData*) hash;
//- (NSData*) hashForSequenceNumber: (long) sequenceNumber from: (MDevice*) device;
- (void) storeSequenceNumbers: (NSDictionary*) seqNumbers forEncodedMessage: (MEncodedMessage*) encoded;

/* Misc identity info queries */
- (BOOL) isBlackListed: (MIdentity*) ident;
- (BOOL) isMe: (IBEncryptionIdentity*) ident;
- (MIdentity*) addClaimedIdentity: (IBEncryptionIdentity*) ident;
- (MIdentity*) addUnclaimedIdentity: (IBEncryptionIdentity*) ident;
- (MDevice *) addDeviceWithName: (uint64_t) deviceName forIdentity: (MIdentity *)ident;

/* Final message handled */
- (void) updateEncodedMetadata: (MEncodedMessage*) encoded;
- (void) insertEncodedMessage: (MEncodedMessage*) encoded forOutgoingMessage: (OutgoingMessage*) om;



@end
