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

@class MObj;

@interface PreparedObj : NSObject {
    int feedType;
    NSData* feedCapability;
    NSString* appId;
    uint64_t timestamp;
    NSString* type;
    NSString* jsonSrc;
    NSData* raw;
    int64_t intKey;
    NSString* stringKey;
}

@property (nonatomic, assign) int feedType;
@property (nonatomic, strong) NSData* feedCapability;
@property (nonatomic, strong) NSString* appId;
@property (nonatomic, assign) uint64_t timestamp;
@property (nonatomic, strong) NSString* type;
@property (nonatomic, strong) NSString* jsonSrc;
@property (nonatomic, strong) NSData* raw;
@property (nonatomic, assign) int64_t intKey;
@property (nonatomic, strong) NSString* stringKey;

- (id) initWithFeedType: (int) ft feedCapability: (NSData*) fc appId: (NSString*) aId timestamp: (uint64_t) ts data: (MObj*) obj;

@end
