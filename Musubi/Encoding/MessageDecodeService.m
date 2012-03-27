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

@synthesize storeFactory, identityProvider, pending, thread;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)sf andIdentityProvider:(id<IdentityProvider>)ip {
    self = [super init];
    if (self) {
        [self setStoreFactory:sf];
        [self setIdentityProvider: ip];
        
        // List of objs pending encoding
        [self setPending: [NSMutableArray arrayWithCapacity:10]];
        
        [self setThread: [[MessageDecodeThread alloc] initWithService:self]];
        [thread start];
        
        [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(process) name:kMusubiNotificationEncodedMessageReceived object:nil];
    }
    
    return self;
}

- (void) process {
    // This is called on some background thread (through notificationCenter), so we need a new store
    PersistentModelStore* store = [storeFactory newStore];
    
    for (MEncodedMessage* msg in [store query:[NSPredicate predicateWithFormat:@"(processed == NO) AND (outbound == NO)"] onEntity:@"EncodedMessage"]) {
        assert(msg.processed == NO);
        
        // Don't process the same obj twice in different threads
        // pending is atomic, so we should be able to do this safely
        // Store ObjectID instead of object, because that is thread-safe
        if ([pending containsObject: msg.objectID]) {
            continue;
        } else {
            [pending addObject: msg.objectID];
        }
        
        // Find the thread to run this on
        [((MessageDecodeThread*)thread).queue insertObject: [[MessageDecodeOperation alloc] initWithMessageId:msg.objectID onThread:((MessageDecodeThread*)thread)] atIndex:0]; 
    }
    
    [((MessageDecodeThread*)thread).queue insertObject: [[MessageDecodedNotifyOperation alloc] init] atIndex:0]; 
}

@end


@implementation MessageDecodeThread

@synthesize service,queue,store,deviceManager,transportManager,identityManager,feedManager,accountManager,appManager,decoder;

- (id)initWithService:(MessageDecodeService *)s {
    self = [super init];
    if (self) {
        [self setService: s];
        [self setQueue:[NSMutableArray array]];
    }
    return self;
}

- (void)main {
    NSLog(@"MessageDecodeThread: Setting up");
    
    // Have to create these in main to be on the running thread
    [self setStore: [service.storeFactory newStore]];
    [self setDeviceManager: [[DeviceManager alloc] initWithStore: store]];
    [self setTransportManager: [[TransportManager alloc] initWithStore:store encryptionScheme: service.identityProvider.encryptionScheme signatureScheme:service.identityProvider.signatureScheme deviceName:[deviceManager localDeviceName]]];
    [self setIdentityManager: transportManager.identityManager];
    [self setFeedManager: [[FeedManager alloc] initWithStore:store]];
    [self setAccountManager: [[AccountManager alloc] initWithStore: store]];
    [self setAppManager: [[AppManager alloc] initWithStore: store]];
    
    [self setDecoder: [[MessageDecoder alloc] initWithTransportDataProvider:transportManager]];
    
    NSLog(@"MessageDecodeThread: Waiting for messages");
    // Perpetually wait for new messages to encode
    while (!self.isCancelled) {
        if (queue.count > 0) {
            NSOperation* op = [queue lastObject];
            [queue removeObject:op];            
            [op start];
        }
        
        // TODO: notification wait
        [NSThread sleepForTimeInterval:0.1];
    }
}

@end

@implementation MessageDecodedNotifyOperation

- (void)main {
    [[Musubi sharedInstance].notificationCenter postNotification:[NSNotification notificationWithName:kMusubiNotificationPlainObjReady object:nil]];
}

@end

@implementation MessageDecodeOperation

@synthesize thread, messageId, dirtyFeeds, shouldRunProfilePush, success;

- (id)initWithMessageId:(NSManagedObjectID *)msgId onThread:(MessageDecodeThread *)t {
    self = [super init];
    if (self) {
        [self setThread: t];
        [self setMessageId: msgId];
        
        [self setDirtyFeeds: [NSMutableArray array]];
    }
    return self;
}

- (void)main {
    // Get the obj and encode it
    MEncodedMessage* msg = (MEncodedMessage*)[thread.store queryFirst:[NSPredicate predicateWithFormat:@"self == %@", messageId] onEntity:@"EncodedMessage"];
    NSLog(@"Decoding %@", msg);
    
    [self decodeMessage:msg];
    
    // Remove from the pending queue
    [thread.service.pending removeObject:messageId];
}

- (BOOL) decodeMessage: (MEncodedMessage*) msg {
    if (msg == nil)
        @throw [NSException exceptionWithName:kMusubiExceptionUnexpected reason:@"Message was nil!" userInfo:nil];
    
    assert (msg != nil);
    IncomingMessage* im = nil;
    @try {
        im = [thread.decoder decodeMessage:msg];
    }
    @catch (NSException *exception) {
        if ([exception.name isEqualToString:kMusubiExceptionNeedEncryptionUserKey]) {
            NSLog(@"Err: %@", exception);
            
            @try {
                IBEncryptionIdentity* errId = (IBEncryptionIdentity*)[exception.userInfo objectForKey:@"identity"];
                if (errId) {
                    NSLog(@"Getting new encryption key for %@", errId);
                    
                    MIdentity* to = [thread.identityManager identityForIBEncryptionIdentity:errId];
                    IBEncryptionUserKey* userKey = [thread.service.identityProvider encryptionKeyForIdentity:errId];
                    
                    if (userKey) {
                        EncryptionUserKeyManager* cryptoUserKeyMgr = thread.transportManager.encryptionUserKeyManager;
                        MEncryptionUserKey* cryptoKey = (MEncryptionUserKey*)[cryptoUserKeyMgr create];
                        [cryptoKey setIdentity: to];
                        [cryptoKey setPeriod: errId.temporalFrame];
                        [cryptoKey setKey: userKey.raw];
                        [cryptoUserKeyMgr createEncryptionUserKey:cryptoKey];
                        
                        // Try again, should work now :)
                        im = [thread.decoder decodeMessage:msg];
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
            if (from.deviceName != thread.deviceManager.localDeviceName) {
                NSLog(@"Failed to decode message %@: %@", msg, exception);
            }
            [thread.store.context deleteObject:msg];
            return YES;
            
        } else {
            NSLog(@"Failed to decode message: %@: %@", msg, exception);
            [thread.store.context deleteObject:msg];
            return YES;
        }
    }
    
    MDevice* device = im.fromDevice;
    MIdentity* sender = im.fromIdentity;
    BOOL whiteListed = YES; //TODO: whitelisting (sender.owned || sender.whitelisted);
    

    PreparedObj* obj = nil;
    @try {
        obj = [ObjEncoder decodeObj: im.data];
        NSLog(@"Decoded obj: %@", obj);
    } @catch (NSException *exception) {
        NSLog(@"Failed to decode message %@: %@", im, exception);
        [thread.store.context deleteObject:msg];
        return YES;
    }
    
    // Look for profile updates, which don't require whitelisting
    /*TODO:
    if (handleProfileUpdate(sender, obj)) {
        //TODO: this may be a lame way of handling this
        Log.d(TAG, "Found profile update from " + sender.musubiName_);
        mEncodedMessageManager.delete(encoded.id_);
        return true;
    }*/
    
    // Handle feed details
    
    if (obj.feedType == kFeedTypeFixed) {
        // Fixed feeds have well-known capabilities.
        NSData* computedCapability = [FeedManager fixedIdentifierForIdentities: im.recipients];
        if (![computedCapability isEqualToData:obj.feedCapability]) {
            NSLog(@"Capability mismatch");
            [thread.store.context deleteObject:msg];
            return YES;
        }
    }
    
    MFeed* feed = nil;
    BOOL asymmetric = NO;
    if (obj.feedType == kFeedTypeAsymmetric || obj.feedType == kFeedTypeOneTimeUse) {
        // Never create well-known broadcast feeds
        feed = [thread.feedManager global];
        asymmetric = YES;
    } else {
        feed = [thread.feedManager feedWithType: obj.feedType andCapability: obj.feedCapability];
    }
    
    if (feed == nil) {
        MFeed* newFeed = (MFeed*)[thread.feedManager create];
        [newFeed setCapability: obj.feedCapability];
        if (newFeed.capability) {
            [newFeed setShortCapability: *(uint64_t*) newFeed.capability.bytes];
        }
        [newFeed setType: obj.feedType];
        [newFeed setAccepted: whiteListed];
        [thread.store save];
        
        [thread.feedManager attachMember: sender toFeed:newFeed];
        
        for (MIdentity* recipient in im.recipients) {
            [thread.feedManager attachMember: recipient toFeed: newFeed];
            
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
            [dirtyFeeds addObject:feed];
        }
        if (feed.type == kFeedTypeExpanding) {
            NSArray* res = [self expandMembershipOfFeed: feed forRecipients: im.recipients andPersonas: im.personas];
            if (((NSNumber*)[res objectAtIndex:0]).boolValue) {
                [dirtyFeeds addObject: feed];
            }
            shouldRunProfilePush |= ((NSNumber*)[res objectAtIndex:1]).boolValue;
        }
    }
    
    MObj* mObj = (MObj*)[thread.store createEntity:@"Obj"]; 
    MApp* mApp = [thread.appManager ensureAppWithAppId: obj.appId];
    NSData* uHash = [ObjEncoder computeUniversalHashFor:im.hash from:sender onDevice:device];
    
    [mObj setFeed:feed];
    [mObj setIdentity: device.identity];
    [mObj setDevice: device];
    [mObj setParent: nil];
    [mObj setApp: mApp];
    [mObj setTimestamp: [NSDate dateWithTimeIntervalSince1970:obj.timestamp]];
    [mObj setUniversalHash: uHash];
    [mObj setShortUniversalHash: *(uint64_t*)uHash.bytes];
    [mObj setType: obj.type];
    [mObj setJson: obj.jsonSrc];
    [mObj setRaw: obj.raw];
    [mObj setLastModified: [NSDate dateWithTimeIntervalSince1970:obj.timestamp]];
    [mObj setEncoded: msg];
    [mObj setDeleted: NO];
    [mObj setRenderable: NO];
    [mObj setProcessed: NO];
    
    // Grant app access
    if (![thread.appManager isSuperApp: mApp]) {
        [thread.feedManager attachApp: mApp toFeed: feed];
    }
    
    // Finish up
    [msg setProcessed: YES];
    [msg setProcessedTime: [NSDate date]];
    
    [thread.store save];        
    success = YES;
    
    NSLog(@"Decoded: %@", mObj);
    
    return YES;
}

- (NSArray*) expandMembershipOfFeed: (MFeed*) feed forRecipients: (NSArray*) recipients andPersonas: (NSArray*) personas {
    
    NSMutableDictionary* participants = [NSMutableDictionary dictionaryWithCapacity:recipients.count];
    for (MIdentity* participant in recipients) {
        [participants setObject:participant forKey:participant.objectID];
    }
    
    for (MIdentity* existing in [thread.feedManager identitiesInFeed: feed]) {
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
    for (MIdentity* participant in participants) {
        [thread.feedManager attachMember:participant toFeed:feed];
        
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