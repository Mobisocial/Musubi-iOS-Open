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
#import "MusubiDeviceManager.h"
#import "TransportManager.h"
#import "SignatureUserKeyManager.h"
#import "IBEncryptionScheme.h"
#import "FeedManager.h"
#import "IdentityManager.h"

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
#import "Authorities.h"
#import "ProfileObj.h"
#import "DeleteObj.h"
#import "LikeObj.h"

#define kSmallProcessorCutOff 20

@implementation MessageEncodeService

@synthesize storeFactory = _storeFactory, identityProvider = _identityProvider, pending = _pending, queues = _queues, pendingLock = _pendingLock;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)sf andIdentityProvider:(id<IdentityProvider>)ip {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.storeFactory = sf;
    self.identityProvider = ip;
    
    // List of objs pending encoding
    self.pending = [NSMutableArray arrayWithCapacity:10];
    self.pendingLock = [[NSLock alloc] init];

    // Two processing threads, one for small feeds, one for large.
    self.queues = [NSArray arrayWithObjects:[NSOperationQueue new], [NSOperationQueue new], nil];
    
    // Start the thread
    for (NSOperationQueue* queue in _queues) {
        [queue setMaxConcurrentOperationCount:1];
    }
    
    [[Musubi sharedInstance].notificationCenter addObserver:self selector:@selector(process) name:kMusubiNotificationPlainObjReady object:nil];
    //in case we bailed with a message in the pipes
    [[Musubi sharedInstance].notificationCenter postNotificationName:kMusubiNotificationPlainObjReady object:nil];

    return self;
}

- (void) process {
    // This is called on some background thread (through notificationCenter), so we need a new store
    PersistentModelStore* store = [_storeFactory newStore];
    
    NSMutableSet* usedQueues = [NSMutableSet setWithCapacity:2];

    for (MObj* obj in [store query:[NSPredicate predicateWithFormat:@"(encoded == nil)"] onEntity:@"Obj"]) {
        
        assert (obj.encoded == nil);
        
        @synchronized(_pendingLock) {
            if ([_pending containsObject: obj.objectID]) {
                continue;
            } else {
                [_pending addObject: obj.objectID];
            }
        }

        // Find the thread to run this on
        NSOperationQueue* queue = nil;
        if([obj.feed.name isEqualToString:kFeedNameGlobalWhitelist] && obj.feed.type == kFeedTypeAsymmetric) {
            queue = [_queues objectAtIndex:0];
        } else {
            NSArray* members = [store query:[NSPredicate predicateWithFormat:@"feed = %@", obj.feed] onEntity:@"FeedMember"];
            if (members.count > kSmallProcessorCutOff) {
                queue = [_queues objectAtIndex:0];
            } else {
                queue = [_queues objectAtIndex:1];
            }
        }
        
        [usedQueues addObject: queue];
        [queue addOperation: [[MessageEncodeOperation alloc] initWithObjId:obj.objectID andService:self]];
    }
    
    // At the end, notify everybody
    for (NSOperationQueue* queue in usedQueues) {
        [queue addOperation: [[MessageEncodedNotifyOperation alloc] init]]; 
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

@synthesize objId = _objId, success, store = _store, service = _service;

- (id)initWithObjId:(NSManagedObjectID *)oId andService:(MessageEncodeService *)service {
    self = [super init];
    if (self) {
        self.service = service;
        self.objId = oId;
        [self setThreadPriority: kMusubiThreadPriorityBackground];
    }
    return self;
}


- (void)main {
    self.store = [_service.storeFactory newStore];
    
    NSError* error;
    MObj* obj = (MObj*)[_store.context objectWithID:_objId];
    if(obj == nil) {
        NSLog(@"Encode failed lookup %@: %@", _objId, error);
    }

    [self encodeObj: obj];
    
    // Remove from the pending queue
    @synchronized(_service.pendingLock) {
        [_service.pending removeObject:_objId];
    }
}

- (void) encodeObj: (MObj*) obj {
    FeedManager * feedManager = [[FeedManager alloc] initWithStore:self.store];
    IdentityManager * identityManager = [[IdentityManager alloc] initWithStore:self.store];
    
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
    if(feed.type == kFeedTypeAsymmetric && [feed.name isEqualToString:kFeedNameGlobalWhitelist]) {
        recipients = [NSMutableArray arrayWithArray:[identityManager claimedIdentities]];
    } else {
        for (MFeedMember* fm in [_store query:[NSPredicate predicateWithFormat:@"feed = %@", feed] onEntity:@"FeedMember"]) {
            [recipients addObject: fm.identity];
        }
    }
    // Create the OutgoingMessage    
    OutgoingMessage* om = [[OutgoingMessage alloc] init];
    PreparedObj* outbound = [ObjEncoder prepareObj:obj forFeed:feed andApp:app];
    
    if (feed.type == kFeedTypeAsymmetric || feed.type == kFeedTypeOneTimeUse) {
        // When broadcasting a message to all friends, don't
        // Leak friend of friend information
        om.blind = YES;
    }
    if([obj.type isEqualToString:kObjTypeDelete] || [obj.type isEqualToString:kObjTypeLike]) {
        //these two renderable obj never need to expand the set of members, and this
        //lets us use the blind flag to help get rid of annoying notifications
        om.blind = YES;
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
    MusubiDeviceManager* deviceManager = [[MusubiDeviceManager alloc] initWithStore:_store];
    MDevice* device = obj.device;
    assert (device.deviceName == [deviceManager localDeviceName]);
    
    [obj setUniversalHash: [ObjEncoder computeUniversalHashFor:om.hash from:sender onDevice:device]];
    [obj setShortUniversalHash: *(uint64_t*)obj.universalHash.bytes];
    
    
    if (localOnly) {
        [self setSuccess: YES];
        return;
    }
    
    id<IdentityProvider> identityProvider = _service.identityProvider;
    TransportManager* transportManager = [[TransportManager alloc] initWithStore:_store encryptionScheme:identityProvider.encryptionScheme signatureScheme:identityProvider.signatureScheme deviceName:deviceManager.localDeviceName];
    MessageEncoder* encoder = [[MessageEncoder alloc] initWithTransportDataProvider:transportManager];
    MEncodedMessage* encoded = nil;
    @try {
        encoded = [encoder encodeOutgoingMessage:om];        
        success = YES;
    }
    @catch (NSException *exception) {
        if ([exception.name isEqualToString:kMusubiExceptionNeedSignatureUserKey]) {
            @try {
                IBEncryptionIdentity* errId = (IBEncryptionIdentity*)[exception.userInfo objectForKey:@"identity"];
                if (errId) {
                    NSLog(@"Making new signature key for %@", errId);
                    
                    IBSignatureUserKey* userKey = [_service.identityProvider signatureKeyForIdentity:errId];
                    
                    if (userKey) {
                        SignatureUserKeyManager* sigUserKeyMgr = transportManager.signatureUserKeyManager;
                        MSignatureUserKey* sigKey = (MSignatureUserKey*)[sigUserKeyMgr create];
                        [sigKey setIdentity: sender];
                        [sigKey setPeriod: errId.temporalFrame];
                        [sigKey setKey: userKey.raw];
                        [sigUserKeyMgr createSignatureUserKey:sigKey];
                        
                        // Try again, should work now :)
                        encoded = [encoder encodeOutgoingMessage:om];
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
    
    if([obj.type isEqualToString:kObjTypeProfile]) {
        [_store.context deleteObject:obj];
    } else {
        obj.encoded = encoded;
    }
    if(feed.type == kFeedTypeOneTimeUse) {
        [feedManager deleteFeedAndMembersAndObjs:feed];
    }
        
    [_store save];
}

@end