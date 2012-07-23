//
//  MLike.h
//  musubi
//
//  Created by MokaFive User on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MIdentity, MObj;

@interface MLike : NSManagedObject

@property (nonatomic) int16_t count;
@property (nonatomic, retain) MObj *obj;
@property (nonatomic, retain) MIdentity *sender;

@end
