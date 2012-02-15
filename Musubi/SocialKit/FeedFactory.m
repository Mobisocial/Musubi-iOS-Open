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
//  FeedFactory.m
//  Musubi
//
//  Created by Willem Bult on 2/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedFactory.h"

@implementation FeedFactory

+ (id) feedFromUri:(NSURL *)uri {
    NSString* name = [[uri pathComponents] lastObject];
    int type = [FeedFactory feedTypeFromName: name];
    
    if (type == FEED_TYPE_FIXED) {
        return [[FixedFeed alloc] initWithName:name andURI:uri];
    } else if (type == FEED_TYPE_GROUP) {
        return [[GroupFeed alloc] initWithName:name andURI:uri];
    } else {
        @throw @"Unsupported feed type";
    }
}


+ (int) feedTypeFromName: (NSString*) name {
    if ([name hasPrefix:@"fixed^"]) {
        return FEED_TYPE_FIXED;
    } else {
        return FEED_TYPE_GROUP;
    }
}
/*
+ (id) feedWithName:(NSString *)name {
    NSString* key = [[NSData generateSecureRandomKeyOf:16] encodeBase64];
    NSString* session = [NSString stringWithFormat:@"%@", CFUUIDCreateString(NULL, CFUUIDCreate(NULL))];
    
    return [[[Feed alloc] initWithName:name session: session key:key] autorelease];
}*/

@end
