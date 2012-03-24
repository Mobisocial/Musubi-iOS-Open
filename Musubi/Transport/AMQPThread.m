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
//  AMQPThread.m
//  Musubi
//
//  Created by Willem Bult on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AMQPThread.h"

#import "NSData+Base64.h"
#import "AMQPConnectionManager.h"
#import "PersistentModelStore.h"

@implementation AMQPThread

static int instanceCount = 0;

@synthesize connMngr, storeFactory, threadStore;

- (id) initWithConnectionManager:(AMQPConnectionManager *)conn storeFactory:(PersistentModelStoreFactory *)sf {
    
    self = [super init];
    if (self) {
        [self setConnMngr: conn];
        [self setStoreFactory: sf];
        
        instance = instanceCount++;
    }
    return self;
}

- (void) log:(NSString*) format, ... {
    va_list args;
    va_start(args, format);
    NSLogv([NSString stringWithFormat: @"AMQPTransport %d: %@", instance, format], args);
    va_end(args);
}

- (NSString*) queueNameForKey: (NSData*) key withPrefix: (NSString*) prefix {
    return [NSString stringWithFormat:@"%@%@", prefix, [key encodeBase64WebSafe]];
}

- (void)main {
    // We need to create a new PersistentModelStore here, because it's not thread-safe
    [self setThreadStore: [storeFactory newStore]];
}


@end
