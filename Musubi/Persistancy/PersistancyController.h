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
//  PersistancyController.h
//  musubi
//
//  Created by Willem Bult on 10/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "ManagedFeed.h"
#import "ManagedMessage.h"
#import "Feed.h"
#import "Obj.h"

@interface PersistancyController : NSObject {
    NSManagedObjectContext* context;
}

@property (nonatomic,retain) NSManagedObjectContext* moc;

- (void) storeObj: (Obj*) o inFeed: (Feed*) f;
- (NSArray*) objsForFeed: (Feed*) f;

- (void) storeFeed: (Feed*) feed;
- (NSArray*) feeds;

@end
