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
//  ObjManager.h
//  Musubi
//
//  Created by Willem Bult on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EntityManager.h"

@class MObj, MFeed, MLikeCache, MIdentity, Obj;

@interface ObjManager : EntityManager

- (id) initWithStore: (PersistentModelStore*) s;

- (MObj*) create;
- (MObj*) createFromObj: (Obj*) obj onFeed: (MFeed*) feed;

- (MObj*) objWithShortUniversalHash: (int64_t) hash;
- (NSArray*) renderableObjsInFeed: (MFeed*) feed;


- (NSArray*) likesForObj: (MObj*) obj;
- (void) saveLikeForObj: (MObj*) obj from: (MIdentity*) sender;

- (MLikeCache*) likeCountForObj: (MObj*) obj;
- (void) increaseLikeCountForObj: (MObj*) obj local: (BOOL) local;

@end
