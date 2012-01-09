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
//  Created by Willem Bult on 10/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "SignedMessage.h"
#import "ManagedUser.h"

@class ManagedFeed;
@class ManagedUser;

@interface ManagedMessage : NSManagedObject

@property (nonatomic, retain) ManagedFeed *feed;
@property (nonatomic, retain) ManagedUser *sender;
@property (nonatomic, retain) NSString * app;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSData * contents;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * id; // can't be named hash; reserved key
@property (nonatomic, retain) NSString * parent;

- (SignedMessage*) message;
- (ManagedMessage*) parentMessage;

@end
