//
//  PreparedObj.h
//  Musubi
//
//  Created by Willem Bult on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MObj;

@interface PreparedObj : NSObject {
    int feedType;
    NSData* feedCapability;
    NSString* appId;
    uint64_t timestamp;
    NSString* type;
    NSString* jsonSrc;
    NSData* raw;
    NSNumber* intKey;
    NSString* stringKey;
}

@property (nonatomic, assign) int feedType;
@property (nonatomic) NSData* feedCapability;
@property (nonatomic) NSString* appId;
@property (nonatomic, assign) uint64_t timestamp;
@property (nonatomic) NSString* type;
@property (nonatomic) NSString* jsonSrc;
@property (nonatomic) NSData* raw;
@property (nonatomic) NSNumber* intKey;
@property (nonatomic) NSString* stringKey;

- (id) initWithFeedType: (int) ft feedCapability: (NSData*) fc appId: (NSString*) aId timestamp: (uint64_t) ts data: (MObj*) obj;

@end
