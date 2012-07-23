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

- (MObj*) objWithUniversalHash: (NSData *) hash;
- (MObj*) latestChildForParent: (MObj*) obj;
- (MObj*)latestStatusObjInFeed:(MFeed *)feed;
- (NSArray*) pictureObjsInFeed: (MFeed*) feed;
- (NSArray*) renderableObjsInFeed: (MFeed*) feed;
- (NSArray *)renderableObjsInFeed:(MFeed *)feed limit:(NSInteger)limit;
- (NSArray *)renderableObjsInFeed:(MFeed *)feed before:(NSDate*)beforeDate limit:(NSInteger)limit;
- (NSArray *)renderableObjsInFeed:(MFeed *)feed after:(NSDate*)afterDate limit:(NSInteger)limit;

- (NSArray*) likesForObj: (MObj*) obj;
- (void) saveLikeForObj: (MObj*) obj from: (MIdentity*) sender;

- (MLikeCache*) likeCountForObj: (MObj*) obj;
- (void) increaseLikeCountForObj: (MObj*) obj local: (BOOL) local;
- (BOOL) feed:(MFeed*)feed withActivityAfter:(NSDate*)start until:(NSDate*)end;
- (MObj*)latestObjOfType:(NSString*)type inFeed:(MFeed *)feed  after:(NSDate*)after before:(NSDate*)before;

@end
