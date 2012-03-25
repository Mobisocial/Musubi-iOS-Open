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
//  MessageEncodeService.m
//  Musubi
//
//  Created by Willem Bult on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MessageEncodeService.h"

#import "NSData+Crypto.h"

#import "Musubi.h"

#import "PersistentModelStore.h"
#import "DeviceManager.h"
#import "TransportManager.h"
#import "SignatureUserKeyManager.h"
#import "IBEncryptionScheme.h"

#import "MObj.h"
#import "MFeed.h"
#import "MDevice.h"
#import "MIdentity.h"
#import "MApp.h"
#import "MFeedMember.h"
#import "MSignatureUserKey.h"

#import "MessageEncoder.h"
#import "ObjEncoder.h"
#import "OutgoingMessage.h"

#define kSmallProcessorCutOff 20

@implementation MessageEncodeService

@synthesize storeFactory, identityProvider, pending, threads;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)sf andIdentityProvider:(id<IdentityProvider>)ip {
    self = [super init];
    if (self) {
        [self setStoreFactory:sf];
        [self setIdentityProvider: ip];
        
        // List of objs pending encoding
        [self setPending: [NSMutableArray arrayWithCapacity:10]];

        // Two processing threads, one for small feeds, one for large.
        [self setThreads:[NSArray arrayWithObjects:[[MessageEncodeThread alloc] initWithService:self],[[MessageEncodeThread alloc] initWithService:self], nil]];
        
        // Start the thread
        for (MessageEncodeThread* thread in threads) {
            [thread start];
        }
        
        [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(process) name:kMusubiNotificationPlainObjReady object:nil];
    }
    
    return self;
}

- (void) process {
    // This is called on some background thread (through notificationCenter), so we need a new store
    PersistentModelStore* store = [storeFactory newStore];
    
    for (MObj* obj in [store query:[NSPredicate predicateWithFormat:@"(encoded == nil)"] onEntity:@"Obj"]) {
        
        assert (obj.encoded == nil);
        
        // Don't process the same obj twice in different threads
        // pending is atomic, so we should be able to do this safely
        // Store ObjectID instead of object, because that is thread-safe
        if ([pending containsObject: obj.objectID]) {
            continue;
        } else {
            [pending addObject: obj.objectID];
        }

        // Find the thread to run this on
        MessageEncodeThread* thread = nil;
        NSArray* members = [store query:[NSPredicate predicateWithFormat:@"feed = %@", obj.feed] onEntity:@"FeedMember"];
        if (members.count > kSmallProcessorCutOff) {
            thread = [threads objectAtIndex:0];
        } else {
            thread = [threads objectAtIndex:1];
        }
        
        [thread.queue insertObject: [[MessageEncodeOperation alloc] initWithObjId:obj.objectID onThread:thread] atIndex:0]; 
    }
    
    // At the end, notify everybody
    for (MessageEncodeThread* thread in threads) {
        [thread.queue insertObject: [[MessageEncodedNotifyOperation alloc] init] atIndex:0]; 
    }
}

@end

@implementation MessageEncodeThread

@synthesize service,queue,store,deviceManager,transportManager,identityManager,encoder;

- (id)initWithService:(MessageEncodeService *)s {
    self = [super init];
    if (self) {
        [self setService: s];
        
        // Only use one thread in the operation queue, because we're not thread safe within (shared store)
        /*[self setQueue: [[NSOperationQueue alloc] init]];
        [queue setMaxConcurrentOperationCount:1];*/
        
        [self setQueue:[NSMutableArray array]];
    }
    return self;
}

- (void)main {
    NSLog(@"MessageEncodeThread: Setting up");
    
    // Have to create these in main to be on the running thread
    [self setStore: [service.storeFactory newStore]];
    [self setDeviceManager: [[DeviceManager alloc] initWithStore: store]];
    [self setTransportManager: [[TransportManager alloc] initWithStore:store encryptionScheme: service.identityProvider.encryptionScheme signatureScheme:service.identityProvider.signatureScheme deviceName:[deviceManager localDeviceName]]];
    [self setIdentityManager: transportManager.identityManager];
    
    [self setEncoder: [[MessageEncoder alloc] initWithTransportDataProvider:transportManager]];
    
    NSLog(@"MessageEncodeThread: Waiting for messages");
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

@implementation MessageEncodedNotifyOperation

- (void)main {
    [[Musubi sharedInstance].notificationCenter postNotification:[NSNotification notificationWithName:kMusubiNotificationAppObjReady object:nil]];
    [[Musubi sharedInstance].notificationCenter postNotification:[NSNotification notificationWithName:kMusubiNotificationPreparedEncoded object:nil]];
}

@end

@implementation MessageEncodeOperation

@synthesize thread, objId, success;

- (id)initWithObjId:(NSManagedObjectID *)oId onThread:(MessageEncodeThread *)t {
    self = [super init];
    if (self) {
        [self setThread: t];
        [self setObjId: oId];
    }
    return self;
}

- (void)main {
    // Get the obj and encode it
    MObj* obj = (MObj*)[thread.store queryFirst:[NSPredicate predicateWithFormat:@"self == %@", objId] onEntity:@"Obj"];
    NSLog(@"Encoding %@", obj);

    [self encodeObj: obj];
    
    // Remove from the pending queue
    [thread.service.pending removeObject:objId];
}

- (void) encodeObj: (MObj*) obj {
    
    // Make sure we have all the required inputs
    assert(obj != nil);

    MFeed* feed = obj.feed;
    assert(feed != nil);
    
    MIdentity* sender = obj.identity;
    assert(sender != nil);
    
    BOOL localOnly = sender.type == kIdentityTypeLocal;
    assert (localOnly || sender.owned);
    
    MApp* app = obj.app;
    assert (app != nil);
    
    NSMutableArray* recipients = [NSMutableArray array];
    for (MFeedMember* fm in [thread.store query:[NSPredicate predicateWithFormat:@"feed = %@", feed] onEntity:@"FeedMember"]) {
        [recipients addObject: fm.identity];
    }
    
    // Create the OutgoingMessage    
    OutgoingMessage* om = [[OutgoingMessage alloc] init];
    PreparedObj* outbound = [ObjEncoder prepareObj:obj forFeed:feed andApp:app];
    NSLog(@"Prepared obj: %@", outbound);
    
    if (feed.type == kFeedTypeAsymmetric || feed.type == kFeedTypeOneTimeUse) {
        // When broadcasting a message to all friends, don't
        // Leak friend of friend information
        [om setBlind: YES];
    }
    
    [om setData: [ObjEncoder encodeObj:outbound]];
    [om setFromIdentity: sender];
    // TODO: insert actual app id here
    [om setApp: [[@"musubi.mobisocial.stanford.edu" dataUsingEncoding:NSUTF8StringEncoding] sha256Digest]];
    [om setRecipients: recipients];
    
    // Remove any blocked people
    for (MIdentity* ident in om.recipients) {
        if (ident.blocked) {
            NSMutableArray* newRcpts = [NSMutableArray arrayWithCapacity:om.recipients.count - 1];
            for (MIdentity* mId in om.recipients) {
                if (!mId.blocked) {
                    [newRcpts addObject:mId];
                }
            }
            
            [om setRecipients: newRcpts];
            break;
        }
    }
    
    [om setHash: [om.data sha256Digest]];
    
    // Universal hash it, must happen before the encoding step so
    // Local messages can still run through the pipeline
    MDevice* device = obj.device;
    assert (device.deviceName == [thread.deviceManager localDeviceName]);
    
    [obj setUniversalHash: [ObjEncoder computeUniversalHashFor:om.hash from:sender onDevice:device]];
    [obj setShortUniversalHash: CFSwapInt64BigToHost(*(uint64_t*)obj.universalHash)];
    
    
    if (localOnly) {
        [self setSuccess: YES];
        return;
    }
    
    MEncodedMessage* encoded = nil;
    @try {
        encoded = [thread.encoder encodeOutgoingMessage:om];        
        success = YES;
    }
    @catch (NSException *exception) {
        if ([exception.name isEqualToString:kMusubiExceptionNeedSignatureUserKey]) {
            NSLog(@"Err: %@", exception);
            
            @try {
                IBEncryptionIdentity* errId = (IBEncryptionIdentity*)[exception.userInfo objectForKey:@"identity"];
                if (errId) {
                    NSLog(@"Making new signature key for %@", errId);
                    
                    IBSignatureUserKey* userKey = [thread.service.identityProvider signatureKeyForIdentity:errId];
                    
                    if (userKey) {
                        SignatureUserKeyManager* sigUserKeyMgr = thread.transportManager.signatureUserKeyManager;
                        MSignatureUserKey* sigKey = (MSignatureUserKey*)[sigUserKeyMgr create];
                        [sigKey setIdentity: sender];
                        [sigKey setPeriod: errId.temporalFrame];
                        [sigKey setKey: userKey.raw];
                        [sigUserKeyMgr createSignatureUserKey:sigKey];
                        
                        // Try again, should work now :)
                        encoded = [thread.encoder encodeOutgoingMessage:om];
                    } else {
                        @throw exception;
                    }
                } else {
                    @throw exception;
                }

            }
            @catch (NSException *exception) {
                NSLog(@"Error: %@", exception);
            }
        } else {
            @throw exception;
        }
    }
    
    obj.encoded = encoded;
    [thread.store save];

}

@end