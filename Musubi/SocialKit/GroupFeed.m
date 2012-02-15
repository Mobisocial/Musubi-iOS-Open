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
//  GroupFeed.m
//  Musubi
//
//  Created by Willem Bult on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GroupFeed.h"

@implementation GroupFeed

@synthesize key, title;

- (id)initWithName:(NSString *)n andURI:(NSURL *)u {
    self = [super initWithName:n type:FEED_TYPE_GROUP uri:u];
    if (self != nil) {
        NSDictionary* query = [uri queryComponents];
        key = [query objectForKey:@"key"];
        title = [query objectForKey:@"groupName"];
    }
    return self;
}

- (id)initWithName:(NSString *)n key:(NSString *)k title:(NSString *)t {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithCapacity:3];
    [dict setValue:[NSString stringWithFormat:@"%@", n] forKey:@"session"];
    [dict setValue:t forKey:@"groupName"];
    [dict setValue:k forKey:@"key"];
    
    NSURL* u = [NSURL URLWithString:[NSString stringWithFormat: @"dungbeetle-group-session://suif.stanford.edu/dungbeetle/index.php?%@", [dict stringFromQueryComponents]]];

    return [self initWithName:n andURI:u];
}

+ (id) createWithTitle:(NSString *)title {
    NSString* key = [[NSData generateSecureRandomKeyOf:16] encodeBase64];
    NSString* session = [NSString stringWithFormat:@"%@", CFUUIDCreateString(NULL, CFUUIDCreate(NULL))];
    
    
    return [[GroupFeed alloc] initWithName:session key:key title:title];
}


@end
