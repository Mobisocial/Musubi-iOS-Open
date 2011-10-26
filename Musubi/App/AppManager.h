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
//  AppManager.h
//  musubi
//
//  Created by Willem Bult on 10/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Download.h"

@protocol AppManagerDelegate
- (void) appManager: (NSObject*) mgr installedApp: (NSString*) name;
@end

@interface AppManager : NSObject<ResourceDownloadDelegate> {
    id<AppManagerDelegate> delegate;
}

@property (nonatomic, retain) id<AppManagerDelegate> delegate;

- (id) initWithDelegate: (id<AppManagerDelegate>) d;
- (NSArray*) apps;
- (void) downloadAppFromURL: (NSURL*) url;

@end
