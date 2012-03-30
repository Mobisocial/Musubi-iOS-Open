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
//  MFeed.h
//  Musubi
//
//  Created by Willem Bult on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define kFeedTypeUnknown 0
#define kFeedTypeFixed 1
#define kFeedTypeExpanding 2
#define kFeedTypeAsymmetric 3
#define kFeedTypeOneTimeUse 4

#define kFeedNameLocalWhitelist @"local_whitelist"
#define kFeedNameProvisionalWhitelist @"provisional_whitelist"

@class MObj;

@interface MFeed : NSManagedObject

@property (nonatomic) int16_t type;
@property (nonatomic, retain) NSData * capability;
@property (nonatomic) int64_t shortCapability;
@property (nonatomic) int64_t latestRenderableObjTime;
@property (nonatomic, retain) MObj* latestRenderableObj;
@property (nonatomic) int32_t numUnread;
@property (nonatomic, retain) NSString * name;
@property (nonatomic) BOOL accepted;
@property (nonatomic) int16_t knownId;

@end
