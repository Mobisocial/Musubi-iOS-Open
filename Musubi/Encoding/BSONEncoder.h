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
//  BSONEncoder.h
//  Musubi
//
//  Created by Willem Bult on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"
#import "Secret.h"
#import "PreparedObj.h"

@interface BSONEncoder : NSObject

+ (NSData*) encodeMessage: (Message*) m;
+ (NSData*) encodeSecret: (Secret*) s;
+ (NSData*) encodeObj: (PreparedObj*) o;

+ (Message*) decodeMessage: (NSData*) data;
+ (Secret*) decodeSecret: (NSData*) data;
+ (PreparedObj*) decodeObj: (NSData*) data;
@end
