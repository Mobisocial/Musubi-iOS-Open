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
//  MessageFormat.m
//  musubi
//
//  Created by Willem Bult on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MessageFormat.h"
#import "DefaultMessageFormat.h"

@implementation MessageFormat

- (EncodedMessage*) encodeMessage: (Message*) msg withKeyPair: (OpenSSLKeyPair*) keyPair {
    @throw [NSException exceptionWithName:@"AbstractClass" reason:@"This method must be implemented in an extending class" userInfo:nil];
}

- (SignedMessage *) decodeMessage: (EncodedMessage *) msg withKeyPair: (OpenSSLKeyPair *) keyPair {
    @throw [NSException exceptionWithName:@"AbstractClass" reason:@"This method must be implemented in an extending class" userInfo:nil];
}

- (NSData *)packMessage:(Message *)msg {
    @throw [NSException exceptionWithName:@"AbstractClass" reason:@"This method must be implemented in an extending class" userInfo:nil];
}

- (SignedMessage *)unpackMessage:(NSData *)plain {
    @throw [NSException exceptionWithName:@"AbstractClass" reason:@"This method must be implemented in an extending class" userInfo:nil];
}

+ (MessageFormat *) defaultMessageFormat {
    return [[[DefaultMessageFormat alloc] init] autorelease];
}

@end
