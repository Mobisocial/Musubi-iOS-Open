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
//  PreparedObj.h
//  Musubi
//
//  Created by Willem Bult on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MObj.h"

@interface PreparedObj : NSObject {
    int feedType;
    NSData* feedCapability;
    NSString* appId;
    long timestamp;
    NSString* type;
    NSString* jsonSrc;
    NSData* raw;
}

@property (nonatomic, assign) int feedType;
@property (nonatomic, retain) NSData* feedCapability;
@property (nonatomic, retain) NSString* appId;
@property (nonatomic, assign) long timestamp;
@property (nonatomic, retain) NSString* type;
@property (nonatomic, retain) NSString* jsonSrc;
@property (nonatomic, retain) NSData* raw;

- (id) initWithFeedType: (int) ft feedCapability: (NSData*) fc appId: (NSString*) aId timestamp: (long) ts data: (MObj*) obj;

@end
