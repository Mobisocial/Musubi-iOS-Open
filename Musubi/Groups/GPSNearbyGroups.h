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
//  GPSNearbyGroups.h
//  musubi
//
//  Created by Willem Bult on 10/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Feed.h"
#import "FeedFactory.h"
#import "LocationController.h"

@protocol GPSNearbyGroupsDelegate <NSObject>

- (void) updatedGroups: (NSArray*) groups;

@end

@interface GPSNearbyGroups : NSObject<LocationControllerDelegate> {
    LocationController* locationCtrl;
    id<GPSNearbyGroupsDelegate> delegate;
}

@property (nonatomic, retain) LocationController* locationCtrl;
@property (nonatomic, retain) id<GPSNearbyGroupsDelegate> delegate;

- (void) findGroups;
- (void) broadcastGroup: (Feed *) group during: (int) minutes withPassword: (NSString*) password;

@end
