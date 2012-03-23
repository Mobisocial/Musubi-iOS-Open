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
//  Message.h
//  Musubi
//
//  Created by Willem Bult on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sender.h"

@interface Message : NSObject {
    uint32_t v; // version
    Sender* s; // information about the sender
    NSData* i; // the iv for the key blocks
    BOOL l; // the blind flag
    NSData* a; // the app id
    NSArray* r; // the key blocks
    NSData* d; // the encrypted data
}

@property (nonatomic, assign) uint32_t v;
@property (nonatomic, retain) Sender* s;
@property (nonatomic, retain) NSData* i;
@property (nonatomic, assign) BOOL l;
@property (nonatomic, retain) NSData* a;
@property (nonatomic, retain) NSArray* r;
@property (nonatomic, retain) NSData* d;

@end
