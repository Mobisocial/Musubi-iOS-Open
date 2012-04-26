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
//  MIdentity.h
//  Musubi
//
//  Created by Willem Bult on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MIdentity : NSManagedObject

@property (nonatomic) BOOL blocked;
@property (nonatomic) BOOL claimed;
@property (nonatomic) int64_t contactId;
@property (nonatomic) int64_t createdAt;
@property (nonatomic) NSString * musubiName;
@property (nonatomic) NSData * musubiThumbnail;
@property (nonatomic) NSString * name;
@property (nonatomic) int64_t nextSequenceNumber;
@property (nonatomic) BOOL owned;
@property (nonatomic) NSString * principal;
@property (nonatomic) NSData * principalHash;
@property (nonatomic) int64_t principalShortHash;
@property (nonatomic) int64_t receivedProfileVersion;
@property (nonatomic) int64_t sentProfileVersion;
@property (nonatomic) NSData * thumbnail;
@property (nonatomic) int16_t type;
@property (nonatomic) int64_t updatedAt;
@property (nonatomic) BOOL whitelisted;

@end
