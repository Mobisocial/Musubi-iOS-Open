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
//  musubi
//
//  Created by Willem Bult on 10/31/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SignedObj.h"

@interface Message : NSObject {
    SignedObj* obj;
    
    NSDate* timestamp;
    NSString* feedName;
    NSString* appId;
    NSString* sender;
}

@property (nonatomic, retain) SignedObj* obj;
@property (nonatomic, retain) NSDate* timestamp;
@property (nonatomic, retain) NSString* feedName;
@property (nonatomic, retain) NSString* appId;
@property (nonatomic, retain) NSString* sender;

@end
