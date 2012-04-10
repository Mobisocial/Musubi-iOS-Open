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
//  MessageDecodeService.m
//  Musubi
//
//  Created by Willem Bult on 3/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MessageDecodeService.h"
#import "Musubi.h"

#import "IBEncryptionScheme.h"

#import "MessageDecoder.h"
#import "ObjEncoder.h"
#import "PreparedObj.h"

#import "PersistentModelStore.h"
#import "DeviceManager.h"
#import "FeedManager.h"
#import "IdentityManager.h"
#import "AccountManager.h"
#import "TransportManager.h"
#import "AppManager.h"
#import "EncryptionUserKeyManager.h"

#import "MEncodedMessage.h"
#import "MEncryptionUserKey.h"
#import "MObj.h"
#import "MFeed.h"
#import "MIdentity.h"

#import "IncomingMessage.h"


@implementation MessageDecodeService

@synthesize storeFactory = _storeFactory, identityProvider = _identityProvider, pending = _pending, queue = _queue;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)sf andIdentityProvider:(id<IdentityProvider>)ip {
    self = [super init];
    if (self) {
        [self setStoreFactory:sf];
        [self setIdentityProvider: ip];
        
        // List of objs pending encoding
        [self setPending: [NSMutableArray arrayWithCapacity:10]];
        
        [self setQueue: [NSOperationQueue new]];
        [_queue setMaxConcurrentOperationCount:1];
        
        [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(process) name:kMusubiNotificationEncodedMessageReceived object:nil];
        [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationEncodedMessageReceived object:nil];
    }
    
    return self;
}

- (void) process {
    // This is called on some background thread (through notificationCenter), so we need a new store
    PersistentModelStore* store = [_storeFactory newStore];

    BOOL messagesQueued = NO;
    for (MEncodedMessage* msg in [store query:[NSPredicate predicateWithFormat:@"(processed == NO) AND (outbound == NO)"] onEntity:@"EncodedMessage"]) {
        assert(msg.processed == NO);
        messagesQueued = YES;
        
        // Don't process the same obj twice in different threads
        // pending is atomic, so we should be able to do this safely
        // Store ObjectID instead of object, because that is thread-safe
        if ([_pending containsObject: msg.objectID]) {
            continue;
        } else {
            [_pending addObject: msg.objectID];
        }
        
        // Find the thread to run this on
        [_queue addOperation: [[MessageDecodeOperation alloc] initWithMessageId:msg.objectID andService:self]]; 
    }
    
    if (messagesQueued)
        [_queue addOperation: [[MessageDecodedNotifyOperation alloc] init]]; 
}

@end


@implementation MessageDecodedNotifyOperation

- (void)main {
    [[Musubi sharedInstance].notificationCenter postNotification:[NSNotification notificationWithName:kMusubiNotificationAppObjReady object:nil]];
}

@end

@implementation MessageDecodeOperation

@synthesize service = _service, messageId = _messageId, dirtyFeeds = _dirtyFeeds, shouldRunProfilePush = _shouldRunProfilePush, success = _success;
@synthesize store = _store, deviceManager = _deviceManager, transportManager = _transportManager, identityManager = _identityManager, feedManager = _feedManager, accountManager = _accountManager, appManager = _appManager, decoder = _decoder;

- (id)initWithMessageId:(NSManagedObjectID *)msgId andService:(MessageDecodeService *)service {
    self = [super init];
    if (self) {
        [self setService: service];
        [self setMessageId: msgId];
        
        [self setDirtyFeeds: [NSMutableArray array]];
    }
    return self;
}

- (BOOL)isConcurrent {
    return YES;
}

- (void)main {
    // Get the obj and decode it
    [self setStore: [_service.storeFactory newStore]];
    MEncodedMessage* msg = (MEncodedMessage*)[_store queryFirst:[NSPredicate predicateWithFormat:@"self == %@", _messageId] onEntity:@"EncodedMessage"];
    
    if (msg) {
        [self setDeviceManager: [[DeviceManager alloc] initWithStore: _store]];
        [self setTransportManager: [[TransportManager alloc] initWithStore:_store encryptionScheme: _service.identityProvider.encryptionScheme signatureScheme:_service.identityProvider.signatureScheme deviceName:[_deviceManager localDeviceName]]];
        [self setIdentityManager: _transportManager.identityManager];
        [self setFeedManager: [[FeedManager alloc] initWithStore:_store]];
        [self setAccountManager: [[AccountManager alloc] initWithStore: _store]];
        [self setAppManager: [[AppManager alloc] initWithStore: _store]];        
        [self setDecoder: [[MessageDecoder alloc] initWithTransportDataProvider:_transportManager]];
        
        NSLog(@"Decoding %@", msg);
        [self decodeMessage:msg];
    }
    
    // Remove from the pending queue
    [_service.pending removeObject:_messageId];
}

- (BOOL) decodeMessage: (MEncodedMessage*) msg {
    if (msg == nil)
        @throw [NSException exceptionWithName:kMusubiExceptionUnexpected reason:@"Message was nil!" userInfo:nil];
    
    assert (msg != nil);
    IncomingMessage* im = nil;
    @try {
        im = [_decoder decodeMessage:msg];
    }
    @catch (NSException *exception) {
        if ([exception.name isEqualToString:kMusubiExceptionNeedEncryptionUserKey]) {
            NSLog(@"Err: %@", exception);
            
            @try {
                IBEncryptionIdentity* errId = (IBEncryptionIdentity*)[exception.userInfo objectForKey:@"identity"];
                if (errId) {
                    NSLog(@"Getting new encryption key for %@", errId);
                    
                    MIdentity* to = [_identityManager identityForIBEncryptionIdentity:errId];
                    IBEncryptionUserKey* userKey = [_service.identityProvider encryptionKeyForIdentity:errId];
                    
                    if (userKey) {
                        EncryptionUserKeyManager* cryptoUserKeyMgr = _transportManager.encryptionUserKeyManager;
                        MEncryptionUserKey* cryptoKey = (MEncryptionUserKey*)[cryptoUserKeyMgr create];
                        [cryptoKey setIdentity: to];
                        [cryptoKey setPeriod: errId.temporalFrame];
                        [cryptoKey setKey: userKey.raw];
                        [_store save];
                        
                        // Try again, should work now :)
                        im = [_decoder decodeMessage:msg];
                    } else {
                        @throw exception;
                    }
                } else {
                    @throw exception;
                }
                
            }
            @catch (NSException *exception) {
                NSLog(@"Failed to decode message beause a user key was required for %@: %@", msg.fromIdentity, exception);
                /*TODO: refresh key
                 if(mKeyUpdateHandler != null) {
                 if (DBG) Log.i(TAG, "Updating key for identity #" + e.identity_, e);
                 mKeyUpdateHandler.requestEncryptionKey(e.identity_);
                 }*/
                return true;
            }
        } else if ([exception.name isEqualToString:kMusubiExceptionDuplicateMessage]){
            MDevice* from = [[exception userInfo] objectForKey:@"from"];
            
            // RabbitMQ does not support the "no deliver to self" routing policy.
            // don't log self-routed device duplicates, everything else we want to know about
            if (from.deviceName != _deviceManager.localDeviceName) {
                NSLog(@"Failed to decode message %@: %@", msg, exception);
            }
            
            [_store.context deleteObject:msg];
            return YES;
            
        } else {
            NSLog(@"Failed to decode message: %@: %@", msg, exception);
            [_store.context deleteObject:msg];
            return YES;
        }
    }
        
    MDevice* device = im.fromDevice;
    MIdentity* sender = im.fromIdentity;
    BOOL whiteListed = YES; //TODO: whitelisting (sender.owned || sender.whitelisted);
    

    PreparedObj* obj = nil;
    @try {
        obj = [ObjEncoder decodeObj: im.data];
    } @catch (NSException *exception) {
        NSLog(@"Failed to decode message %@: %@", im, exception);
        [_store.context deleteObject:msg];
        return YES;
    }
    
    // Look for profile updates, which don't require whitelisting
    if ([obj.type isEqualToString:@"profile"]) {
        /*TODO:
         if (handleProfileUpdate(sender, obj)) {
         //TODO: this may be a lame way of handling this
         Log.d(TAG, "Found profile update from " + sender.musubiName_);
         mEncodedMessageManager.delete(encoded.id_);
         return true;
         }*/
        [_store.context deleteObject:msg];
        return true;
    }
    
    // Handle feed details
    
    if (obj.feedType == kFeedTypeFixed) {
        // Fixed feeds have well-known capabilities.
        NSData* computedCapability = [FeedManager fixedIdentifierForIdentities: im.recipients];
        if (![computedCapability isEqualToData:obj.feedCapability]) {
            NSLog(@"Capability mismatch");
            [_store.context deleteObject:msg];
            return YES;
        }
    }

    MFeed* feed = nil;
    BOOL asymmetric = NO;
    if (obj.feedType == kFeedTypeAsymmetric || obj.feedType == kFeedTypeOneTimeUse) {
        // Never create well-known broadcast feeds
        feed = [_feedManager global];
        asymmetric = YES;
    } else {
        feed = [_feedManager feedWithType: obj.feedType andCapability: obj.feedCapability];
    }
    
    if (feed == nil) {
        MFeed* newFeed = (MFeed*)[_feedManager create];
        [newFeed setCapability: obj.feedCapability];
        if (newFeed.capability) {
            [newFeed setShortCapability: *(uint64_t*) newFeed.capability.bytes];
        }
        [newFeed setType: obj.feedType];
        [newFeed setAccepted: whiteListed];
        [_store save];
        
        [_feedManager attachMember: sender toFeed:newFeed];
        
        for (MIdentity* recipient in im.recipients) {
            [_feedManager attachMember: recipient toFeed: newFeed];
            
            /*TODO:
             // Send a profile request if we don't have one from them yet
             if (recipient.receivedProfileVersion == 0 || recipient.receivedProfileVersion == [NSNull null]) {
             // We don't really want N profiles, but we may or may not be
             // friends, so its best to ask with any relevant identities to
             // maximize the chance we can know who the sender is
             for(MIdentity persona in im.personas) {
             sendProfileRequest(persona, recipient);
             }
             }
             */
        }
        
        /* TODO:
         // If this feed is accepted, then we should send a profile to
         // all of the other people in it that we don't know
         if (newFeed.accepted) {
         for(MIdentity* persona in im.personas) {
         MAccount* provisionalAccount = [thread.accountManager provisionalWhiteListForIdentity: persona];
         MAccount* whitelistAccount = [thread.accountManager whiteListForIdentity: persona];
         
         for (MIdentity* recipient in im.recipients) {
         shouldRunProfilePush |= [thread.feedManager addRecipient: recipient toWhitelistsIfNecessaryWithProvisional: provisionalAccount whitelist: whitelistAccount andPersona: persona];
         }
         }
         }
         */
        
        feed = newFeed;
    } else {
        if (!feed.accepted && whiteListed && !asymmetric) {
            feed.accepted = YES;
            [_dirtyFeeds addObject:feed];
        }
        if (feed.type == kFeedTypeExpanding) {
            NSArray* res = [self expandMembershipOfFeed: feed forRecipients: im.recipients andPersonas: im.personas];
            if (((NSNumber*)[res objectAtIndex:0]).boolValue) {
                [_dirtyFeeds addObject: feed];
            }
            _shouldRunProfilePush |= ((NSNumber*)[res objectAtIndex:1]).boolValue;
        }
    }
    
    MObj* mObj = (MObj*)[_store createEntity:@"Obj"]; 
    MApp* mApp = [_appManager ensureAppWithAppId: obj.appId];
    NSData* uHash = [ObjEncoder computeUniversalHashFor:im.hash from:sender onDevice:device];
    
    [mObj setFeed:feed];
    [mObj setIdentity: device.identity];
    [mObj setDevice: device];
    [mObj setParent: nil];
    [mObj setApp: mApp];
    [mObj setTimestamp: [NSDate dateWithTimeIntervalSince1970:obj.timestamp / 1000]];
    [mObj setUniversalHash: uHash];
    [mObj setShortUniversalHash: *(uint64_t*)uHash.bytes];
    [mObj setType: obj.type];
    [mObj setJson: obj.jsonSrc];
    [mObj setRaw: obj.raw];
    [mObj setLastModified: [NSDate dateWithTimeIntervalSince1970:obj.timestamp / 1000]];
    [mObj setEncoded: msg];
    [mObj setDeleted: NO];
    [mObj setRenderable: NO];
    [mObj setProcessed: NO];
    
    // Grant app access
    if (![_appManager isSuperApp: mApp]) {
        [_feedManager attachApp: mApp toFeed: feed];
    }
    
    // Finish up
    [msg setProcessed: YES];
    [msg setProcessedTime: [NSDate date]];
    
    [_store save];        
    _success = YES;
    
    NSLog(@"Decoded: %@", mObj);
    
    return YES;
}

- (NSArray*) expandMembershipOfFeed: (MFeed*) feed forRecipients: (NSArray*) recipients andPersonas: (NSArray*) personas {
    
    NSMutableDictionary* participants = [NSMutableDictionary dictionaryWithCapacity:recipients.count];
    for (MIdentity* participant in recipients) {
        [participants setObject:participant forKey:participant.objectID];
    }
    
    for (MIdentity* existing in [_feedManager identitiesInFeed: feed]) {
        [participants removeObjectForKey: existing.objectID];
    }
    /* TODO: whitelist
    NSMutableArray* provisionalAccounts = [NSMutableArray arrayWithCapacity: personas.count];
    NSMutableArray* whitelistAccounts = [NSMutableArray arrayWithCapacity: personas.count];
    
    for (MIdentity* persona in personas) {
        [provisionalAccounts addObject:[thread.accountManager provisionalWhitelistForIdentity: persona]];
        [whitelistAccounts addObject:[thread.accountManager whitelistForIdentity: persona]];
    }*/
    
    BOOL shouldRunProfilePushBecauseOfExpand = NO;
    for (MIdentity* participant in participants.allValues) {
        [_feedManager attachMember:participant toFeed:feed];
        
        /* TODO: profile requests
        // Send a profile request if we don't have one from them yet
        if(participant.receivedProfileVersion == 0) {
            // We don't really want N profiles, but we may or may not be
            // friends, so its best to ask with any relevant identities to
            // maximize the chance we can know who the sender is
            for (MIdentity* persona in personas) {
                sendProfileRequest(persona, recipient);
            }
        }
        */
        
        /* TODO: whitelist 
        if (feed.accepted) {
            for (int i=0; i<personas.count; i++) {
                shouldRunProfilePush |= [thread.feedManager addRecipient: participant toWhitelistsIfNecessaryWithProvisional: [provisionalAccounts objectAtIndex:i] whitelist: [whitelistAccounts objectAtIndex:i] andPersona: [personas objectAtIndex:i]];
            }
        }*/
    }
    
    return [NSArray arrayWithObjects:[NSNumber numberWithBool:participants.count > 0], [NSNumber numberWithBool: shouldRunProfilePushBecauseOfExpand], nil];
}

@end