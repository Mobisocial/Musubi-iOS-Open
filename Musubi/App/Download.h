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
//  ResourceManager.h
//  musubi
//
//  Created by Willem Bult on 10/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSData+CocoaDevUsersAdditions.h"

@protocol ResourceDownloadDelegate
    - (void) resourceSavedToPath: (NSString*) path;
@end

@interface Download : NSObject<NSURLConnectionDelegate, NSURLConnectionDataDelegate> {
    NSString* path;
    
    id<ResourceDownloadDelegate> delegate;

    BOOL started;
    NSMutableData* fileData;
}

@property (nonatomic,retain) NSMutableData* fileData;
@property (nonatomic,retain) NSString* path;
@property (nonatomic,retain) id<ResourceDownloadDelegate> delegate;

- (id) initWithPath: (NSString*) p andDelegate: (id<ResourceDownloadDelegate>) d;
- (void) startWithURL: (NSURL*) url;
@end
