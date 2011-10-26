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
//  Group.h
//  musubi
//
//  Created by Willem Bult on 10/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XQueryComponents.h"
#import "GroupMember.h"

@interface Group : NSObject {
    NSString* name;
    NSURL* feedUri;
    NSString* feedName;
    NSString* key;
    NSArray* members;
}

@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSURL* feedUri;
@property (nonatomic, retain) NSString* feedName;
@property (nonatomic, retain) NSString* key;
@property (nonatomic, retain) NSArray* members;

- (id) initWithName: (NSString*) n feedUri: (NSURL*) uri;
- (NSArray*) publicKeys;

@end
