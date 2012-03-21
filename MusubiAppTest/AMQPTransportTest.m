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
//  AMQPTransportTest.m
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AMQPTransportTest.h"
#import "MessageListener.h"
#import "TransportManager.h"
#import "UserKeyManager.h"
#import "EncodedMessageManager.h"
#import "NSData+Crypto.h"
#import "MessageEncoder.h"
#import "Musubi.h"

@implementation AMQPTransportTest

@synthesize identityProvider, store;

- (void) setUp {
    [self setIdentityProvider: [[UnverifiedIdentityProvider alloc] init]];
    
    NSURL* storePath = [PersistentModelStore pathForStoreWithName:@"TestStore1"];
    [[NSFileManager defaultManager] removeItemAtPath:storePath.path error:NULL];
    
    [self setStore: [[PersistentModelStore alloc] initWithCoordinator:[PersistentModelStore coordinatorWithName:@"TestStore1"]]];
    
    MDevice* dev = [store createDevice];
    [dev setDeviceName:random()];
}

- (BOOL) waitForConnection: (AMQPTransport*) transport during: (NSTimeInterval) interval {
    NSDate* start = [NSDate date];
    while (true) {
        if ([[NSDate date] timeIntervalSinceDate:start] > interval)
            break;
        
        if ([[transport connMgrOut] connectionIsAlive] || [[transport connMngr] connectionIsAlive])
            return true;
        
        [NSThread sleepForTimeInterval: .1];
    }
    
    return false;
}

- (BOOL) waitForDisconnect: (AMQPTransport*) transport during: (NSTimeInterval) interval {
    NSDate* start = [NSDate date];
    while (true) {
        if ([[NSDate date] timeIntervalSinceDate:start] > interval)
            break;
        
        if ([transport done])
            return true;
        
        [NSThread sleepForTimeInterval: .1];
    }
    
    return false;
}

- (void) testSendAToBWithBFirst
{    
    // Initiate managers with the identity provider
    TransportManager* transportManager = [[TransportManager alloc] initWithStore:store encryptionScheme:[identityProvider encryptionScheme] signatureScheme:[identityProvider signatureScheme] deviceName:random()];
    
    UserKeyManager* keyManager = [[UserKeyManager alloc] initWithStore:store encryptionScheme:[identityProvider encryptionScheme] signatureScheme:[identityProvider signatureScheme]];

    // Set up our identity
    IBEncryptionIdentity* me = [self randomIdentity];
    MIdentity* mIdent0 = [transportManager addClaimedIdentity: me];
    [mIdent0 setOwned: YES];
    [mIdent0 setPrincipal: me.principal];
    [[transportManager identityManager] updateIdentity:mIdent0];
    

    // Set up the signature key
    IBEncryptionIdentity* requiredKey = [me keyAtTemporalFrame:[transportManager signatureTimeFrom:mIdent0]];
    MSignatureUserKey* signatureKey = (MSignatureUserKey*)[keyManager create];
    [signatureKey setIdentity: mIdent0];
    [signatureKey setKey: [identityProvider signatureKeyForIdentity: requiredKey].raw]; 
    [signatureKey setPeriod: requiredKey.temporalFrame];
    [keyManager createSignatureUserKey: signatureKey];
    
    // Set up receiving identity
    IBEncryptionIdentity* you = [self randomIdentity];
    // Start AMQP listener for receiver
    MessageListener* listener = [[MessageListener alloc] initWithIdentityProvider:identityProvider andIdentity:you];
    STAssertTrue([self waitForConnection: listener.transport during: 20.0], @"Connection was not established in time");
    
    // Wait a bit for the listener to be done fetching messages from the initial queue
    [NSThread sleepForTimeInterval:3];

    // Start AMQP transport (sender)
    AMQPTransport* transport = [[AMQPTransport alloc] initWithStoreCoordinator:transportManager.store.context.persistentStoreCoordinator encryptionScheme:identityProvider.encryptionScheme signatureScheme:identityProvider.signatureScheme deviceName:transportManager.deviceName];
    [transport start];
    //EncodedMessageManager* emManager = [[EncodedMessageManager alloc] initWithStore: [PersistentModelStore sharedInstance]];
    
    // Make an outgoing message
    OutgoingMessage* om = [[OutgoingMessage alloc] init];
    [om setData:[NSData generateSecureRandomKeyOf:32]];
    [om setApp: [NSData generateSecureRandomKeyOf:32]];
    [om setFromIdentity: [[[transportManager identityManager] ownedIdentities] objectAtIndex: 0]];
    [om setRecipients: [NSArray arrayWithObject: [transportManager addClaimedIdentity:you]]];
    [om setHash: [[om data] sha256Digest]];
    
    // Encode the message, inserts into DB, so AMQPTransport will pick it up
    MessageEncoder* encoder = [[MessageEncoder alloc] initWithTransportDataProvider: transportManager];
    MEncodedMessage* encodedOutgoing = [encoder encodeOutgoingMessage: om];
    //[[store context] save:NULL];
    
    // Allow 20 seconds for AMQP to connect and send the message
    STAssertTrue([self waitForConnection: transport during: 20.0], @"Connection was not established in time");
    
    /*
    BOOL received = NO;
    for (int i=0; i++;) {
        MEncodedMessage* encodedIncoming = [listener waitForMessage:i during:2.0];
        STAssertNotNil(encodedIncoming, @"Did not receive message");
        
        if ([encodedIncoming.encoded isEqualToData:encodedOutgoing.encoded]) {
            received = YES;
            break;
        }
    }
    
    STAssertTrue(received, @"Did not receive an equal message");*/

    
    MEncodedMessage* encodedIncoming = [listener waitForMessage:0 during:20.0];
    STAssertNotNil(encodedIncoming, @"Did not receive message");
    STAssertTrue([encodedOutgoing.encoded isEqualToData: encodedIncoming.encoded], @"Messages were not equal");
    
    
    // Drain the queue
    int msg = 1;
    while (encodedIncoming != nil) {
        encodedIncoming = [listener waitForMessage:msg++ during:3.0];
    }
    
    [transport stop];
    [listener stop];
    
    // Wait for connections to close
    STAssertTrue([self waitForDisconnect: transport during: 20.0], @"Connection was not closed in time");
    STAssertTrue([self waitForDisconnect: listener.transport during: 20.0], @"Connection was not closed in time");

}

- (void) testSendAToBWithAFirst
{
    // Initiate managers with the identity provider
    TransportManager* transportManager = [[TransportManager alloc] initWithStore:store encryptionScheme:[identityProvider encryptionScheme] signatureScheme:[identityProvider signatureScheme] deviceName:random()];

    UserKeyManager* keyManager = [[UserKeyManager alloc] initWithStore:store encryptionScheme:[identityProvider encryptionScheme] signatureScheme:[identityProvider signatureScheme]];

    // Set up our identity
    IBEncryptionIdentity* me = [self randomIdentity];
    MIdentity* mIdent0 = [transportManager addClaimedIdentity: me];
    [mIdent0 setOwned: YES];
    [mIdent0 setPrincipal: me.principal];
    [[transportManager identityManager] updateIdentity:mIdent0];
    
    // Set up the signature key
    IBEncryptionIdentity* requiredKey = [me keyAtTemporalFrame:[transportManager signatureTimeFrom:mIdent0]];
    MSignatureUserKey* signatureKey = (MSignatureUserKey*)[keyManager create];
    [signatureKey setIdentity: mIdent0];
    [signatureKey setKey: [identityProvider signatureKeyForIdentity: requiredKey].raw]; 
    [signatureKey setPeriod: requiredKey.temporalFrame];
    [keyManager createSignatureUserKey: signatureKey];

    // Start AMQP transport (sender)
    AMQPTransport* transport = [[AMQPTransport alloc] initWithStoreCoordinator:transportManager.store.context.persistentStoreCoordinator encryptionScheme:identityProvider.encryptionScheme signatureScheme:identityProvider.signatureScheme deviceName:transportManager.deviceName];
    [transport start];
    
    // Set up receiving identity
    IBEncryptionIdentity* you = [self randomIdentity];
    
    // Make an outgoing message
    OutgoingMessage* om = [[OutgoingMessage alloc] init];
    [om setData:[NSData generateSecureRandomKeyOf:32]];
    [om setApp: [NSData generateSecureRandomKeyOf:32]];
    [om setFromIdentity: [[[transportManager identityManager] ownedIdentities] objectAtIndex: 0]];
    [om setRecipients: [NSArray arrayWithObject: [transportManager addClaimedIdentity:you]]];
    [om setHash: [[om data] sha256Digest]];
    
    // Encode the message, inserts into DB, so AMQPTransport will pick it up
    MessageEncoder* encoder = [[MessageEncoder alloc] initWithTransportDataProvider: transportManager];
    MEncodedMessage* encodedOutgoing = [encoder encodeOutgoingMessage: om];
    
    // Allow 20 seconds for AMQP to connect and send the message
    STAssertTrue([self waitForConnection: transport during: 20.0], @"Connection was not established in time");

    // Start AMQP listener for receiver
    MessageListener* listener = [[MessageListener alloc] initWithIdentityProvider:identityProvider andIdentity:you];
    STAssertTrue([self waitForConnection: listener.transport during: 20.0], @"Connection was not established in time");
    
    MEncodedMessage* encodedIncoming = [listener waitForMessage:0 during:20.0];
    STAssertNotNil(encodedIncoming, @"Did not receive message");
    STAssertTrue([encodedOutgoing.encoded isEqualToData: encodedIncoming.encoded], @"Messages were not equal");
    
    // Drain the queue
    int msg = 1;
    while (encodedIncoming != nil) {
        encodedIncoming = [listener waitForMessage:msg++ during:3.0];
    }
    
    [transport stop];
    [listener stop];
    
    // Wait for connections to close
    
    STAssertTrue([self waitForDisconnect: transport during: 20.0], @"Connection was not closed in time");
    STAssertTrue([self waitForDisconnect: listener.transport during: 20.0], @"Connection was not closed in time");

}

@end
