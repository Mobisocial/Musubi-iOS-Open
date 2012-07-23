//
//  MDevice.h
//  musubi
//
//  Created by MokaFive User on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MIdentity;

@interface MDevice : NSManagedObject

@property (nonatomic) int64_t deviceName;
@property (nonatomic) int64_t maxSequenceNumber;
@property (nonatomic, retain) MIdentity *identity;

@end
