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

@implementation AMQPTransport

@synthesize connMngr, connMgrOut, sender, listener;

- (id)initWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator encryptionScheme:(IBEncryptionScheme *)es signatureScheme:(IBSignatureScheme *)ss deviceName:(long)devName {

    self = [super init];
    if (self) {
        [self setConnMngr:[[[AMQPConnectionManager alloc] init] autorelease]];
        [self setConnMgrOut:[[[AMQPConnectionManager alloc] init] autorelease]];
        //        [self setConnMgrOut:connMngr];

        [self setListener: [[AMQPListener alloc] initWithConnectionManager:connMngr storeCoordinator:coordinator encryptionScheme:es signatureScheme:ss deviceName:devName]];
        [self setSender: [[AMQPSender alloc] initWithConnectionManager:connMgrOut storeCoordinator:coordinator encryptionScheme:es signatureScheme:ss deviceName:devName]];

    }
    return self;
}

- (id)initWithTransportDataProvider:(id<TransportDataProvider>)tdp {
    self = [super init];
    if (self) {
        [self setConnMngr:[[[AMQPConnectionManager alloc] init] autorelease]];
//        [self setConnMgrOut:[[[AMQPConnectionManager alloc] init] autorelease]];
        [self setConnMgrOut:connMngr];
    }
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

- (BOOL)done {
    return [sender isFinished] && [listener isFinished];
}

@end