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
//  RabbitMQMessengerService.h
//  musubi
//
//  Created by Willem Bult on 10/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import "amqp.h"
#import "amqp_framing.h"
#import "utils.h"
#import "OutgoingMessage.h"
#import "Identity.h"
#import "MessageFormat.h"

@interface RabbitMQMessengerService : NSObject {
    MessageFormat* messageFormat;
    Identity* identity;
}

@property (nonatomic, retain) MessageFormat* messageFormat;
@property (nonatomic, retain) Identity* identity;

- (NSString*) queueForKey: (OpenSSLPublicKey*) key;
- (NSString*) routeForKeys: (NSArray*) keys;

- (void) runWithPublicKey: (NSString*) pubKey;
- (void) sendMessage: (OutgoingMessage*) msg;
@end