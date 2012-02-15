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
//  Feed.m
//  musubi
//
//  Created by Willem Bult on 10/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Feed.h"

@implementation Feed

@synthesize type, name, uri, members;

- (id)initWithName:(NSString *)n type:(int) t uri:(NSURL*)u {
    self = [super init];
    if (self != nil) {
        [self setType: t];
        [self setName: n];
        [self setUri: u];
        [self setMembers: [NSArray array]];
    }
    return self;
}

- (NSArray *)publicKeys {
    NSMutableArray* keys = [NSMutableArray arrayWithCapacity:[members count]];
    for (User* member in members) {
        [keys addObject: [member id]];
    }
    return keys;
}

- (NSDictionary *)json {
    NSMutableDictionary* dict = [[[NSMutableDictionary alloc] initWithCapacity:6] autorelease];
    [dict setObject:[self name] forKey:@"name"];
//    [dict setObject:[[self uri] description] forKey:@"uri"];
//    [dict setObject:[self session] forKey:@"session"];
//    [dict setObject:[self key] forKey:@"key"];
    
    NSMutableArray* memberDict = [[[NSMutableArray alloc] init] autorelease];
    for (User* user in members) {
        [memberDict addObject:[user json]];
    }
    
    [dict setObject:memberDict forKey:@"members"];
    
    return dict;
}
/*
- (NSURL *)uri {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] initWithCapacity:3];
    [dict setValue:[NSString stringWithFormat:@"%@", session] forKey:@"session"];
    [dict setValue:name forKey:@"groupName"];
    [dict setValue:key forKey:@"key"];
    
    return [NSURL URLWithString:[NSString stringWithFormat: @"dungbeetle-group-session://suif.stanford.edu/dungbeetle/index.php?%@", [dict stringFromQueryComponents]]];
}*/


- (NSString *)description {
    NSMutableString* desc = [NSMutableString string];
    [desc appendString:@"<Group: "];
    [desc appendString:name];
    [desc appendString:@", ["];
    for (User* member in members) {
        [desc appendString:[NSString stringWithFormat:@"%@, ", [member description]]];
    }
    [desc appendString:@"]>"];
    return desc;
}
@end
