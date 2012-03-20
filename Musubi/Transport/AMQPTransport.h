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
//  AMQPTransport.h
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMQPConnectionManager.h"
#import "EncodedMessageManager.h"
#import "TransportDataProvider.h"
#import "DeviceManager.h"
#import "IdentityManager.h"

@interface AMQPTransport : NSObject {
    AMQPConnectionManager* connMngr;
    AMQPConnectionManager* connMgrOut;
    
    EncodedMessageManager* messageManager;
    DeviceManager* deviceManager;
    IdentityManager* identityManager;

    id<TransportDataProvider> transportDataProvider;
    
    NSMutableArray* declaredGroups;
    NSMutableDictionary* waitingForAck;    
    
    int instance;
    
    BOOL stopListener;
    BOOL stopSender;
    
    BOOL senderRunning;
    
    NSThread* inThread;
    NSThread* outThread;
}

@property (nonatomic,retain) AMQPConnectionManager* connMngr;
@property (nonatomic,retain) AMQPConnectionManager* connMgrOut;

@property (nonatomic,retain) NSMutableArray* declaredGroups;
@property (nonatomic,retain) NSMutableDictionary* waitingForAck;

@property (nonatomic,retain) id<TransportDataProvider> transportDataProvider;

@property (nonatomic,retain) EncodedMessageManager* messageManager;
@property (nonatomic,retain) DeviceManager* deviceManager;
@property (nonatomic,retain) IdentityManager* identityManager;

@property (nonatomic,retain) NSThread* inThread;
@property (nonatomic,retain) NSThread* outThread;

- (id) initWithTransportDataProvider: (id<TransportDataProvider>) tdp;

- (void) start;
- (void) startListener;
- (void) startSender;
- (void) stop;
- (BOOL) done;

- (void) listen;
//- (void) consumeMessagesFromQueue: (amqp_bytes_t) queue;
- (void) consumeMessagesFromQueue: (NSString*) queue perpetually: (BOOL) perpetual;

- (void) send;
- (void) sendMessage: (MEncodedMessage*) msg;
- (void) confirmDelivery: (uint32_t) deliveryTag succeeded: (BOOL) ack;

@end
