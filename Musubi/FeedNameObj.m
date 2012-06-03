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
//  FeedNameObj.m
//  musubi
//
//  Created by MokaFive User on 6/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedNameObj.h"
#import "MObj.h"
#import "MFeed.h"

static NSString* kNameField = @"name";

@implementation FeedNameObj

@synthesize name = _name;

- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        self.type = kObjTypeFeedName;
        self.name = name;
        self.data = [NSDictionary dictionaryWithObjectsAndKeys:name, kNameField, nil];        
    }
    
    return self;
}

- (id)initWithData:(NSDictionary *)data {
    return [self initWithName: [data objectForKey:kNameField]];
}

/**
 Performs obj-specific processing. Return true to keep
 the object in the data store, false to discard it.
 */
- (BOOL)processObjWithRecord: (MObj*) obj {
    obj.feed.name = _name;
    return YES;
}
@end
