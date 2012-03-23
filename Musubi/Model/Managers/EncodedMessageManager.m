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
//  EncodedMessageManager.m
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EncodedMessageManager.h"

@implementation EncodedMessageManager

- (id)initWithStore:(PersistentModelStore *)s {
    self = [super initWithEntityName:@"EncodedMessage" andStore:s];
    if (self != nil) {
    }
    return self;
}

- (MEncodedMessage *)lookupById:(uint32_t)i {
    return (MEncodedMessage*)[self queryFirst: [NSPredicate predicateWithFormat:@"id = %u", i]];
}

- (NSArray*) unsentOutboundMessages {
    return [self query:[NSPredicate predicateWithFormat:@"processed=0 AND outbound=1"]];
}

@end
