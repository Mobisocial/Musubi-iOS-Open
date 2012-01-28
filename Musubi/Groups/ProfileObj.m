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
//  ProfileObj.m
//  Musubi
//
//  Created by Willem Bult on 1/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ProfileObj.h"

@implementation ProfileObj

- (id)initWithUser:(User*)user {
    
    self = [super initWithType:kObjTypeProfile];
    if (self != nil) {
        NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:2];
        [dict setObject:[user name] forKey:@"name"];
        [dict setObject:[UIDevice currentDevice].name forKey:@"about"];
        
        [self setData:dict];
    }
    
    return self;
}
@end
