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
//  SignedMessage.m
//  musubi
//
//  Created by Willem Bult on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SignedMessage.h"
#import "SBJson.h"

@implementation SignedMessage

@synthesize hash;

- (NSString *)description {
    return [NSString stringWithFormat:@"<SignedMessage: %@, %@, %@, %@, %@, %@, %@, %@>", hash, parentHash, obj, sender, recipients, appId, feedName, timestamp];
}

- (NSDictionary *)json {
    long long ts = (long long)([[self timestamp] timeIntervalSince1970] * 1000);

    NSMutableDictionary* dict = [[[NSMutableDictionary alloc] initWithCapacity:6] autorelease];

    [dict setObject:[self appId] forKey:@"appId"];
    [dict setObject:[self feedName] forKey:@"feedName"];
    [dict setObject:[NSString stringWithFormat: @"%qi", ts] forKey:@"timestamp"];
    [dict setObject:[self hash] forKey:@"hash"];
    [dict setObject:[[self sender] json] forKey:@"sender"];
    [dict setObject:[[self obj] json] forKey:@"obj"];
    return dict;
}

- (BOOL) belongsToHash: (NSString*) h {
    return ([[self hash] isEqualToString:h] || [[self parentHash] isEqualToString:h]);
}

+ (id)createFromMessage:(Message *)msg withHash:(NSString *)hash {
    SignedMessage* signedMsg = [[[SignedMessage alloc] init] autorelease];
    [signedMsg setObj: [msg obj]];
    [signedMsg setAppId: [msg appId]];
    [signedMsg setFeedName: [msg feedName]];
    [signedMsg setTimestamp: [msg timestamp]];
    [signedMsg setHash: hash];
    [signedMsg setSender: [msg sender]];
    [signedMsg setRecipients: [msg recipients]];
    [signedMsg setParentHash: [msg parentHash]];
    return signedMsg;
}

@end
