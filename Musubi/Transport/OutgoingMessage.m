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
//  OutgoingMessage.m
//  musubi
//
//  Created by Willem Bult on 10/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "OutgoingMessage.h"

@implementation OutgoingMessage 

@synthesize toPublicKeys;

- (id)initWithObj:(SignedObj *)o publicKeys:(NSArray *)pks feedName:(NSString *)fn appId:(NSString *)ai {
    self = [super init];
    if (self != nil) {
        [self setObj: o];
        [self setToPublicKeys: pks];
        [self setFeedName: fn];
        [self setAppId: ai];
        [self setTimestamp: [NSDate date]];
    }
    return self;
}

- (NSData*) message {
    long long ts = (long long)([timestamp timeIntervalSince1970] * 1000);
    NSMutableDictionary* complemented = [NSMutableDictionary dictionaryWithDictionary: [obj json]];
    [complemented setValue:feedName forKey:@"feedName"];
    [complemented setValue:appId forKey:@"appId"];
    [complemented setValue:[NSString stringWithFormat: @"%qi", ts] forKey:@"timestamp"];
    
    NSLog(@"Sending: %@", complemented);
    
    SBJsonWriter* jsonWriter = [[[SBJsonWriter alloc] init] autorelease];
    NSString* json = [jsonWriter stringWithObject: complemented];
    return [json dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<OutgoingMessage: %@, to: %@>", [super description], toPublicKeys];
}

@end