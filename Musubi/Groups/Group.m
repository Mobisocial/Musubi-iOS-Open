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
//  Group.m
//  musubi
//
//  Created by Willem Bult on 10/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Group.h"

@implementation Group

@synthesize name, feedUri, session, key, members;

- (id)initWithName:(NSString *)n feedUri:(NSURL *)uri {
    self = [super init];
    if (self != nil) {
        [self setName: n];
        [self setFeedUri: uri];
        [self setMembers: [NSArray array]];
        
        NSDictionary* uriComponents = [uri queryComponents];
        [self setSession: [[uriComponents objectForKey:@"session"] objectAtIndex:0]];
        [self setKey: [[uriComponents objectForKey:@"key"] objectAtIndex:0]];
    }
    return self;
}

- (NSArray *)publicKeys {
    NSMutableArray* keys = [NSMutableArray arrayWithCapacity:[members count]];
    for (GroupMember* member in members) {
        [keys addObject: [member publicKey]];
    }
    return keys;
}

- (NSString *)description {
    NSMutableString* desc = [NSMutableString string];
    [desc appendString:@"<Group: "];
    [desc appendString:name];
    [desc appendString:@", ["];
    for (GroupMember* member in members) {
        [desc appendString:[NSString stringWithFormat:@"%@, ", [member description]]];
    }
    [desc appendString:@"]>"];
    return desc;
}

- (GroupMember *)memberByPublicKey:(NSString *)publicKey {
    for (GroupMember* member in members) {
        if ([[member publicKey] isEqualToString:publicKey]) {
            return member;
        }
    }
    
    return nil;
}
@end
