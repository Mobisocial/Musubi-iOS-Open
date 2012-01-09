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
//  App.m
//  musubi
//
//  Created by Willem Bult on 11/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "App.h"

@implementation App 

@synthesize id, feed, message, users;

- (NSDictionary *)json {
    NSMutableDictionary* dict = [[[NSMutableDictionary alloc] initWithCapacity:3] autorelease];
    [dict setObject:[self id] forKey:@"id"];
    [dict setObject:[[self feed] json] forKey:@"feed"];
    [dict setObject:[[self message] json] forKey:@"message"];
    /*
    NSMutableArray* userDict = [[NSMutableArray alloc] init];
    for (User* user in users) {
        [userDict addObject:[user json]];
    }
    
    [dict setObject:userDict forKey:@"users"];*/
    
    return dict;
}

@end
