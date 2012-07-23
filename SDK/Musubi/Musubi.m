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
//  Musubi.m
//  musubi
//
//  Created by Willem Bult on 10/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Musubi.h"

#import "NSData+Crypto.h"
#import "NSData+Base64.h"

#import "UnverifiedIdentityProvider.h"
#import "AphidIdentityProvider.h"

#import "IBEncryptionScheme.h"

#import "MessageEncoder.h"
#import "MessageEncodeService.h"
#import "MessageDecodeService.h"
#import "AMQPTransport.h"
#import "AddressBookIdentityManager.h"
#import "ObjProcessorService.h"

#import "PersistentModelStore.h"
#import "FeedManager.h"
#import "AccountManager.h"
#import "IdentityManager.h"
#import "IdentityKeyManager.h"
#import "TransportManager.h"
#import "MApp.h"
#import "MFeed.h"
#import "MIdentity.h"
#import "MObj.h"
#import "MEncodedMessage.h"

#import "IntroductionObj.h"
#import "Authorities.h"

#import "CorralHTTPServer.h"
#import "APNPushManager.h"

@implementation Musubi

static Musubi* _sharedInstance = nil;

@synthesize mainStore, storeFactory, notificationCenter, keyManager, encodeService, decodeService, transport, objPipelineService, apnDeviceToken, addressBookIdentityUpdater, identityProvider;
@synthesize corralHTTPServer;

+(Musubi*)sharedInstance
{
	@synchronized([Musubi class])
	{
		if (!_sharedInstance) {
			_sharedInstance = [[self alloc] init];
        }
        
		return _sharedInstance;
	}
    
	return nil;
}

- (id)init {
    self = [super init];
    
    if (self == nil) 
        return self;
    
    // The store factory creates stores for other threads, the main store is used on the main thread
    self.storeFactory = [PersistentModelStoreFactory sharedInstance];
    self.mainStore = storeFactory.rootStore;
    
    [self cleanUp];
    
    // The notification sender informs every major part in the system about what's going on
    self.notificationCenter = [[NSNotificationCenter alloc] init];
            
    [self performSelectorInBackground:@selector(startServices) withObject:nil];
   
    return self;
}

- (void) cleanUp {
    NSArray* res = [self.mainStore query:[NSPredicate predicateWithFormat:@"principalShortHash == 0 AND principal == null AND name == null"] onEntity:@"Identity"];
    NSLog(@"Deleting %d unknown contacts", res.count);
    for (MIdentity* i in res) {
        [self.mainStore.context deleteObject:i];
    }
    
    res = [self.mainStore query:[NSPredicate predicateWithFormat:@"(feed == nil) OR (identity == nil)"] onEntity:@"FeedMember"];
    NSLog(@"Deleting %d corrupt feed members", res.count);
    for (MObj* i in res) {
        [self.mainStore.context deleteObject:i];
    }

    NSDate* weekAgo = [NSDate dateWithTimeIntervalSinceNow:-604800.0];
    res = [self.mainStore query:[NSPredicate predicateWithFormat:@"(encoded != nil) AND (sent == NO OR sent == nil) AND (lastModified < %@)", weekAgo] onEntity:@"Obj"];
    NSLog(@"Marking %d old objs as sent", res.count);
    for (MObj* i in res) {
        i.sent = YES;
    }
    
    res = [self.mainStore query:[NSPredicate predicateWithFormat:@"(processed == YES AND sent == YES AND encoded != nil)"] onEntity:@"Obj"];
    NSLog(@"Deleting %d processed encoded messages", res.count);
    for (MObj* i in res) {
        [self.mainStore.context deleteObject:i.encoded];
        i.encoded = nil;
    }
    
    [self.mainStore save];
}

- (void) startServices {
    // The identity provider is our main IBE point of contact
    self.identityProvider = [[AphidIdentityProvider alloc] init];
    
    // The key manager handles our encryption and signature keys
    self.keyManager = [[IdentityKeyManager alloc] initWithIdentityProvider: identityProvider];
    
    // The encoding service encodes all our messages, to be picked up by the transport
    self.encodeService = [[MessageEncodeService alloc] initWithStoreFactory: storeFactory andIdentityProvider:identityProvider];
    [self.encodeService start];
    
    // The decoding service decodes incoming encoded messages
    self.decodeService = [[MessageDecodeService alloc] initWithStoreFactory: storeFactory andIdentityProvider:identityProvider];
    [self.decodeService start];
    
    // The transport sends and receives raw data from the network
    self.transport = [[AMQPTransport alloc] initWithStoreFactory:storeFactory];
    [transport start];
    
    // The obj pipeline will process our objs so we can render them
    self.objPipelineService = [[ObjProcessorService alloc] initWithStoreFactory: storeFactory];
    [self.objPipelineService start];
    
    // Make sure we keep the facebook friends up to date
    self.addressBookIdentityUpdater = [[AddressBookIdentityManager alloc] initWithStoreFactory: storeFactory];
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:kAddressBookIdentityUpdaterFrequency target:self.addressBookIdentityUpdater selector:@selector(refreshFriendsIfNeeded) userInfo:nil repeats:YES] forMode:NSDefaultRunLoopMode];
}

- (void) stopServices {
}

- (void) restart {    
    [self stopServices];
    [self startServices];
}

- (PersistentModelStore *) newStore {
    return [storeFactory newStore];
}

- (void) onAppLaunch {
    NSDate* showUIDate = [NSDate dateWithTimeIntervalSinceNow:1];
    
    [Musubi sharedInstance];
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    
    
    // Pause on the loading screen for a bit, for awesomeness display reasons
    [NSThread sleepUntilDate:showUIDate];
}

- (void)onRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"received remote notification while running %@", userInfo);
    
    if( [userInfo objectForKey:@"local"] != NULL &&
       [userInfo objectForKey:@"amqp"] != NULL)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 6 * NSEC_PER_SEC), dispatch_get_current_queue(), ^{
            //TODO: good and racy
            NSNumber* amqp = (NSNumber*)[userInfo objectForKey:@"amqp"]; 
            int local = [APNPushManager tallyLocalUnread]; 
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:(amqp.intValue + local) ];
        });
    }    
}

- (void)onAppDidBecomeActive {
    // launch the corral service
    self.corralHTTPServer = [[CorralHTTPServer alloc] init];
    NSError* corralError;
    if ([self.corralHTTPServer start:&corralError]) {
        NSLog(@"Corral server running on port %hu", [self.corralHTTPServer listeningPort]);
    } else {
        NSLog(@"Error starting corral server: %@", corralError);
    }
}

- (void)onAppWillResignActive {
    [APNPushManager resetLocalUnreadInBackgroundTask:NO];
    
    // Shutdown corral http server
    [self.corralHTTPServer stop];
    self.corralHTTPServer = nil;
}

- (BOOL) handleURL: (NSURL*) url fromSourceApplication: (NSString*) sourceApplication {
    return NO;
}

+ (NSString *)urlForObjRaw:(MObj *)obj {
    return [CorralHTTPServer urlForRaw:obj];
}


@end
