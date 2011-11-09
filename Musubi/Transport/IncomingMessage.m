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
//  IncomingMessage.m
//  musubi
//
//  Created by Willem Bult on 10/28/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "IncomingMessage.h"

@implementation IncomingMessage

+ (id)readFromJSON:(NSData *)json withSender:(NSString *)sender {
    SBJsonParser* parser = [[[SBJsonParser alloc] init] autorelease];
    NSDictionary* dict = [parser objectWithData: json];
    
    double_t timestamp = [(NSString*)[dict objectForKey:@"timestamp"] doubleValue];
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:(int)(timestamp / 1000)];
    
    IncomingMessage* msg = [[[IncomingMessage alloc] init] autorelease];
    [msg setTimestamp: date];
    [msg setSender: sender];
    [msg setFeedName: [dict objectForKey:@"feedName"]];
    [msg setAppId: [dict objectForKey:@"appId"]];
    
    SignedObj* obj = [SignedObj readFromJSON: dict];
    [obj setTimestamp: date];
    [obj setSenderPublicKey: sender];
    [msg setObj: obj];
    
    return msg;
}

@end
