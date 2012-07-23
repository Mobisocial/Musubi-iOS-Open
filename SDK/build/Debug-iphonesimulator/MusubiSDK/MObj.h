//
//  MObj.h
//  musubi
//
//  Created by MokaFive User on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MApp, MDevice, MEncodedMessage, MFeed, MIdentity, MLike, MObj;

@interface MObj : NSManagedObject

@property (nonatomic) BOOL deleted;
@property (nonatomic, retain) NSString * json;
@property (nonatomic, retain) NSDate* lastModified;
@property (nonatomic) BOOL processed;
@property (nonatomic) BOOL sent;
@property (nonatomic, retain) NSData * raw;
@property (nonatomic) NSNumber * intKey;
@property (nonatomic, retain) NSString * stringKey;
@property (nonatomic) BOOL renderable;
@property (nonatomic) int64_t shortUniversalHash;
@property (nonatomic, retain) NSDate* timestamp;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSData * universalHash;
@property (nonatomic, retain) MApp *app;
@property (nonatomic, retain) MDevice *device;
@property (nonatomic, retain) MEncodedMessage *encoded;
@property (nonatomic, retain) MFeed *feed;
@property (nonatomic, retain) MIdentity *identity;
@property (nonatomic, retain) NSSet *likes;
@property (nonatomic, retain) MObj *parent;
@end

@interface MObj (CoreDataGeneratedAccessors)

- (void)addLikesObject:(MLike *)value;
- (void)removeLikesObject:(MLike *)value;
- (void)addLikes:(NSSet *)values;
- (void)removeLikes:(NSSet *)values;

@end
