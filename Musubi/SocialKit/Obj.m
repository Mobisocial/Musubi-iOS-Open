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
//  Obj.m
//  musubi
//
//  Created by Willem Bult on 10/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Obj.h"

@implementation Obj

@synthesize type, data, raw;

- (id)initWithType:(NSString *)t {
    self = [super init];
    if (self != nil) {
        [self setType: t];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<Obj: %@, %@>", type, data];
}
/*
- (NSDictionary *)json {
    NSMutableDictionary* dict = [[[NSMutableDictionary alloc] init] autorelease];
    [dict setObject:type forKey:@"type"];
    [dict setObject:data forKey:@"data"];
    return dict;
}*/


@end
