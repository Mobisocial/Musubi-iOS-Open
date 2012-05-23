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
//  MObj.h
//  musubi
//
//  Created by Ben Dodson on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MApp, MDevice, MEncodedMessage, MFeed, MIdentity, MObj, MLikeCache;

@interface MObj : NSManagedObject

@property (nonatomic) BOOL deleted;
@property (nonatomic) NSString * json;
@property (nonatomic) NSDate * lastModified;
@property (nonatomic) BOOL processed;
@property (nonatomic) NSData * raw;
@property (nonatomic) BOOL renderable;
@property (nonatomic) int64_t shortUniversalHash;
@property (nonatomic) NSDate * timestamp;
@property (nonatomic) NSString * type;
@property (nonatomic) NSData * universalHash;
@property (nonatomic) MApp *app;
@property (nonatomic) MDevice *device;
@property (nonatomic) MEncodedMessage *encoded;
@property (nonatomic) MFeed *feed;
@property (nonatomic) MIdentity *identity;
@property (nonatomic) MObj *parent;
@property (nonatomic) MLikeCache *likeCount;

- (NSString *)senderDisplay;

@end
