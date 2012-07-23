//
//  MSequenceNumber.h
//  musubi
//
//  Created by MokaFive User on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MEncodedMessage, MIdentity;

@interface MSequenceNumber : NSManagedObject

@property (nonatomic) int64_t sequenceNumber;
@property (nonatomic, retain) MEncodedMessage *encodedMessage;
@property (nonatomic, retain) MIdentity *recipient;

@end
