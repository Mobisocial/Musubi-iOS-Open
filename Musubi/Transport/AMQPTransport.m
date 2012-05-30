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
//  AMQPTransport.m
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AMQPTransport.h"
#import "Musubi.h"
#import "AMQPConnectionManager.h"
#import "AMQPSender.h"
#import "AMQPListener.h"

@implementation AMQPTransport

@synthesize connMngr, sender, listener;

- (id)initWithStoreFactory:(PersistentModelStoreFactory *)storeFactory {

    self = [super init];
    if (!self) return nil;
    
    connMngr = [[AMQPConnectionManager alloc] init];
    listener = [[AMQPListener alloc] initWithConnectionManager:connMngr storeFactory:storeFactory];
    sender = [[AMQPSender alloc] initWithConnectionManager:connMngr storeFactory:storeFactory];
    [[Musubi sharedInstance].notificationCenter addObserver:listener selector:@selector(restart) name:kMusubiNotificationOwnedIdentityAvailable object:nil];

    return self;
}

- (void) start {
    [sender start];
    [listener start];
}

- (void)stop {
    [sender cancel];
    [listener cancel];
}

- (void) restart {
    NSLog(@"Restarting transport");
    
    /*
    void (^waitUntilDone)(void) = ^(void) {
        while (true) {
            if ([self done]) {
                [self start];
                break;
            } else {
                NSLog(@"Waiting to stop");
                [NSThread sleepForTimeInterval:0.1];
            }
        }
    };
    
    [self stop];
    
    dispatch_queue_t thread = dispatch_queue_create("transport_restart_queue", NULL);
    dispatch_async(thread, waitUntilDone);
    dispatch_release(thread);*/
}

- (BOOL)done {
    return [sender isFinished] && [listener isFinished];
}

@end