//
//  MEncodedMessage.h
//  musubi
//
//  Created by MokaFive User on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MDevice, MIdentity;

@interface MEncodedMessage : NSManagedObject

@property (nonatomic, retain) NSData * encoded;
@property (nonatomic, retain) NSData * messageHash;
@property (nonatomic) BOOL outbound;
@property (nonatomic) BOOL processed;
@property (nonatomic, retain) NSDate* processedTime;
@property (nonatomic) int64_t sequenceNumber;
@property (nonatomic) int64_t shortMessageHash;
@property (nonatomic, retain) MDevice *fromDevice;
@property (nonatomic, retain) MIdentity *fromIdentity;

@end
