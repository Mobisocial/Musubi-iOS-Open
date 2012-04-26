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
//  ObjManager.m
//  Musubi
//
//  Created by Willem Bult on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ObjManager.h"
#import "SBJSON.h"
#import "MObj.h"
#import "MFeed.h"
#import "Obj.h"

@implementation ObjManager

- (id)initWithStore:(PersistentModelStore *)s {
    self = [super initWithEntityName:@"Obj" andStore:s];
    if (self) {
        
    }
    return self;
}

- (MObj*) create {
    return (MObj*) [super create];
}

- (MObj*) createFromObj: (Obj*) obj onFeed: (MFeed*) feed {
    
    SBJsonWriter* writer = [[SBJsonWriter alloc] init];
    NSString* json = [writer stringWithObject:obj.data];
    
    MObj* mObj = [self create];
    [mObj setType: obj.type];
    [mObj setJson: json];
    [mObj setRaw: obj.raw];
    [mObj setFeed: feed];
    
    return mObj;
}

- (NSArray *)renderableObjsInFeed:(MFeed *)feed {
    return [self query:[NSPredicate predicateWithFormat:@"(feed == %@) AND (parent == nil) AND (renderable == YES) AND ((processed == YES) OR (encoded == nil))", feed.objectID] sortBy:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:FALSE]];
}

@end
