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
//  FeedItem.h
//  musubi
//
//  Created by Willem Bult on 5/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Three20/Three20.h"

@interface FeedItem : TTTableLinkedItem {
    NSString* _sender;
    NSDate* _timestamp;
    UIImage* _profilePicture;
}

@property (nonatomic, copy) NSString* sender;
@property (nonatomic, retain) NSDate* timestamp;
@property (nonatomic, copy) UIImage* profilePicture;

@end
