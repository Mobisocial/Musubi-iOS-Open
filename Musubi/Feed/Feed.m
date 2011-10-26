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
//  Created by Willem Bult on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Feed.h"

@implementation Feed 

@synthesize group;

- (id)initWithGroup:(Group *)g {
    self = [super init];
    if (self != nil) {
        [self setGroup: g];
    }
    return self;
}

- (void) insert: (Obj *)obj forApp: (NSString*) app {
    OutgoingMessage* msg = [[OutgoingMessage alloc] initWithObj:obj publicKeys:[group publicKeys] feedName:[group feedName] appId:app];
    RabbitMQMessengerService* messenger = [[RabbitMQMessengerService alloc] init];
    [messenger sendMessage: msg];
}

@end
