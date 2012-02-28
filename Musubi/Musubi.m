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

@implementation Musubi

static Musubi* _sharedInstance = nil;

@synthesize feedListeners;


+(Musubi*)sharedInstance
{
	@synchronized([Musubi class])
	{
		if (!_sharedInstance)
			[[self alloc] init];
        
		return _sharedInstance;
	}
    
	return nil;
}

+(id)alloc
{
	@synchronized([Musubi class])
	{
		NSAssert(_sharedInstance == nil, @"Attempted to allocate a second instance of a singleton.");
		_sharedInstance = [super alloc];
		return _sharedInstance;
	}
    
	return nil;
}

- (id)init {
    self = [super init];
    
    if (self != nil) {
        /*
        transport = [[RabbitMQMessengerService alloc] initWithListener:self];
        feedListeners = [[NSMutableDictionary alloc] init];
        messageFormat = [[MessageFormat defaultMessageFormat] retain];
        identity = [Identity sharedInstance];
        
        [identity setDelegate:self];*/
    }
    
    return self;
}

- (void)dealloc {
//    [messageFormat release];
    [feedListeners release];
//    [transport release];
    
    [super dealloc];
}

- (void)startTransport {
//    [NSThread detachNewThreadSelector:@selector(run) toTarget:transport withObject:nil];
}

/*
- (int)handleIncoming:(EncodedMessage *)encoded {
    // decode
    SignedMessage* msg = [messageFormat decodeMessage:encoded withKeyPair:[identity deviceKey]];
    NSLog(@"Incoming: %@", msg);
    NSLog(@"JSON: %@", [[msg obj] json]);
    
    // save
    ManagedFeed* mgdFeed = [[ObjectStore sharedInstance] feedForSession: [msg feedName]];
    [mgdFeed storeMessage:msg];
    
    if ([[[msg obj] type] isEqualToString: kObjTypeJoinNotification]) {
        NSLog(@"Somebody joined the feed: %@", [msg sender]);
        
        Feed* feed = [mgdFeed feed];
        if ([feed isKindOfClass:GroupFeed.class]) {
            NSLog(@"Old: %@", feed);
            [[[[GroupProvider alloc] init] autorelease] updateFeed: (GroupFeed*) feed sinceVersion:-1];
            [mgdFeed updateFromFeed:feed];
            NSLog(@"New: %@", feed);
        } else {
            @throw @"A JoinNotificationObj was sent for a non-group feed";
        }
    }

    

    // and notify
    NSArray* listeners = [feedListeners objectForKey: [msg feedName]];
    if (listeners != nil) {
        for (id<MusubiFeedListener> listener in listeners) {
            [listener newMessage:msg];
        }
    }
    
    return 1;
}

- (NSArray *)groups {
    NSMutableArray* groups = [NSMutableArray array];
    for (ManagedFeed* mgdFeed in [[ObjectStore sharedInstance] feeds]) {
        [groups addObject: [mgdFeed feed]];
    }
    return groups;
}

- (NSArray*) friends {
    NSMutableArray* friends = [NSMutableArray array];
    for (ManagedUser* mgdUser in [[ObjectStore sharedInstance] users]) {
        User* user = [mgdUser user];
        [friends addObject: user];
    }
    return friends;
}

- (ManagedFeed*) joinGroupFeed:(GroupFeed *)feed {
    [[[[GroupProvider alloc] init] autorelease] updateFeed:feed sinceVersion:-1];
    
    ManagedFeed* existing = [[ObjectStore sharedInstance] feedForSession:[feed name]];
    if (existing != nil) {
        
        JoinNotificationObj* jno = [[[JoinNotificationObj alloc] initWithURI:[[feed uri] absoluteString]] autorelease];
        
        App* app = [[[App alloc] init] autorelease];
        [app setId: kMusubiAppId];
        [app setFeed: feed];
        [self sendMessage:[Message createWithObj:jno forApp:app]];
        
        return existing;
    }
    
    
    ManagedFeed* mgdFeed = [[ObjectStore sharedInstance] storeFeed: feed];
    
    JoinNotificationObj* jno = [[[JoinNotificationObj alloc] initWithURI:[[feed uri] absoluteString]] autorelease];

    App* app = [[[App alloc] init] autorelease];
    [app setId: kMusubiAppId];
    [app setFeed: feed];
    [self sendMessage:[Message createWithObj:jno forApp:app]];
    
    return mgdFeed;
}

- (ManagedFeed *)feedByName:(NSString *)feedName {
    return [[ObjectStore sharedInstance] feedForSession:feedName];
}


- (void)listenToGroup:(Feed *)group withListener:(id<MusubiFeedListener>)listener {
    NSMutableArray* listeners = [feedListeners objectForKey: [group name]];
    if (listeners == nil) {
        listeners = [NSMutableArray arrayWithCapacity:1];
        [feedListeners setObject:listeners forKey:[group name]];
    }
    
    [listeners addObject:listener];
}

- (SignedMessage*) sendMessage: (Message*) msg {
    EncodedMessage* encoded = [messageFormat encodeMessage:msg withKeyPair:[identity deviceKey]];
    
    // TODO: Find a neater way to get the SignedMessage before it's sent
    SignedMessage* signedMsg = [messageFormat unpackMessage: [messageFormat packMessage: msg]];
    [signedMsg setHash: [encoded hash]];
    [signedMsg setSender: [identity user]];
    [signedMsg setRecipients: [msg recipients]];

    // send
    [transport sendMessage:encoded to:[msg recipients]];
    
    // and save
    ManagedFeed* feed = [[ObjectStore sharedInstance] feedForSession: [msg feedName]];
    [feed storeMessage:signedMsg];
    
    // and notify
    NSArray* listeners = [feedListeners objectForKey: [msg feedName]];
    if (listeners != nil) {
        for (id<MusubiFeedListener> listener in listeners) {
            [listener newMessage:signedMsg];
        }
    }
    
    return signedMsg;
}

- (User *)userWithPublicKey:(NSData *)publicKey {
    ManagedUser* user = [[ObjectStore sharedInstance] userWithPublicKey:publicKey];
    return [user user];
}

- (void)userProfileChangedTo:(User *)user {
    if ([user picture] != nil) {
        ProfilePictureObj* pictureObj = [[ProfilePictureObj alloc] initWithUser:user reply:TRUE];
        Message* m = [Message createWithObj:pictureObj forUsers: [self friends]];
        [self sendMessage: m];
    }
    
    ProfileObj* obj = [[ProfileObj alloc] initWithUser:user];
    Message* m = [Message createWithObj:obj forUsers:[self friends]];
    [self sendMessage:m];
}*/

@end
