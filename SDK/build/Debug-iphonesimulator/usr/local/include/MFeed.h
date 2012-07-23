//
//  MFeed.h
//  musubi
//
//  Created by MokaFive User on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MObj;

#define kFeedTypeUnknown 0
#define kFeedTypeFixed 1
#define kFeedTypeExpanding 2
#define kFeedTypeAsymmetric 3
#define kFeedTypeOneTimeUse 4

#define kFeedNameLocalWhitelist @"local_whitelist"
#define kFeedNameProvisionalWhitelist @"provisional_whitelist"
#define kFeedNameGlobalWhitelist @"global_whitelist"

@interface MFeed : NSManagedObject

@property (nonatomic) BOOL accepted;
@property (nonatomic, retain) NSData * capability;
@property (nonatomic) int16_t knownId;
@property (nonatomic) int64_t latestRenderableObjTime;
@property (nonatomic, retain) NSString * name;
@property (nonatomic) int32_t numUnread;
@property (nonatomic) int64_t shortCapability;
@property (nonatomic) int16_t type;
@property (nonatomic, retain) MObj *latestRenderableObj;
@property (nonatomic, retain) NSData* thumbnail;

@end
