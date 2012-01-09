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
//  Message.m
//  musubi
//
//  Created by Willem Bult on 10/31/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Message.h"
#import "SBJson.h"
#import "Identity.h"

@implementation Message

@synthesize obj, sender, recipients, appId, feedName, timestamp, parentHash;

- (NSString *)description {
    return [NSString stringWithFormat:@"<Message: %@, %@, %@, %@, %@, %@, %@>", obj, parentHash, sender, recipients, appId, feedName, timestamp];
}

+ (id) createWithObj: (Obj*) obj forApp: (id) app {
    NSMutableArray* pubKeys = [NSMutableArray arrayWithArray:[[app feed] publicKeys]];
    NSString* myPubKey = [[Identity sharedInstance] publicKeyBase64];
    while ([pubKeys containsObject:myPubKey]) {
        [pubKeys removeObject: myPubKey];
    }
    
    Message* msg = [[[Message alloc] init] autorelease];
    [msg setObj:obj];
    [msg setSender:[[Identity sharedInstance] user]];
    [msg setRecipients:pubKeys];
    [msg setAppId:[app id]];
    [msg setFeedName:[[app feed] session]];
    [msg setTimestamp:[NSDate date]];
    if ([[app message] parentHash] != nil) {
        [msg setParentHash: [[app message] parentHash]];
    } else {
        [msg setParentHash: [[app message] hash]];
    }
    
    return msg;
}

@end