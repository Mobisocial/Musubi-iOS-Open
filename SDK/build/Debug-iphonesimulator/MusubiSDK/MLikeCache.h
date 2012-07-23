//
//  MLikeCache.h
//  musubi
//
//  Created by Ben Dodson on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MObj;

@interface MLikeCache : NSManagedObject

@property (nonatomic) int16_t count;
@property (nonatomic) int16_t localLike;
@property (nonatomic, retain) MObj *parentObj;

@end
