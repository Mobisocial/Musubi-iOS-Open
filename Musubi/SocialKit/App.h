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
//  App.h
//  musubi
//
//  Created by Willem Bult on 11/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Feed.h"
#import "Message.h"

@interface App : NSObject {
    NSString* id;

    Feed* feed;
    Message* message;
    
    NSArray* users;
}

@property (nonatomic,retain) NSString* id;
@property (nonatomic,retain) Feed* feed;
@property (nonatomic,retain) Message* message;
@property (nonatomic,retain) NSArray* users;

- (NSDictionary *)json;

@end
