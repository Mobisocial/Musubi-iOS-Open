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
//  Musubi.h
//  musubi
//
//  Created by Willem Bult on 10/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Obj.h"
#import "User.h"
#import "App.h"
#import "GroupProvider.h"
#import "JoinNotificationObj.h"
#import "ProfileObj.h"
#import "ProfilePictureObj.h"
#import "MessageFormat.h"
#import "RabbitMQMessengerService.h"

static NSString* kMusubiAppId = @"edu.stanford.mobisocial.dungbeetle";

@protocol MusubiFeedListener

- (void) newMessage: (SignedMessage*) message;

@end

@interface Musubi : NSObject<TransportListener,IdentityDelegate> {
    RabbitMQMessengerService* transport;
    MessageFormat* messageFormat;
    Identity* identity;

    NSMutableDictionary* feedListeners;
}

@property (nonatomic, retain) NSMutableDictionary* feedListeners;

+ (Musubi*) sharedInstance;
- (void) startTransport;

- (NSArray*) friends;
- (NSArray*) groups;
- (ManagedFeed*) joinGroup: (Feed*) group;
- (ManagedFeed*) feedByName: (NSString*) feedName;


- (void) listenToGroup: (Feed*) group withListener: (id<MusubiFeedListener>) listener;
- (SignedMessage*) sendMessage: (Message*) msg;

- (User*) userWithPublicKey: (NSData*) publicKey;

@end
