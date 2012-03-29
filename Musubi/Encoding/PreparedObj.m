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
//  PreparedObj.m
//  Musubi
//
//  Created by Willem Bult on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PreparedObj.h"
#import "MObj.h"

@implementation PreparedObj

@synthesize appId, feedCapability, feedType, jsonSrc, raw, timestamp, type;

- (id)initWithFeedType:(int)ft feedCapability:(NSData *)fc appId:(NSString *)aId timestamp:(uint64_t)ts data:(MObj *)obj {
    self = [super init];
    if (self) {
        [self setAppId: aId];
        [self setFeedType: ft];
        [self setFeedCapability: fc];
        [self setTimestamp: ts];
        [self setType: obj.type];
        [self setJsonSrc: obj.json];
        [self setRaw: obj.raw];
    }
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<PreparedObj: %@, %d, %@, %llu, %@, %@>", appId, feedType, feedCapability, timestamp, type, jsonSrc];
}

@end
