//
//  MSignatureUserKey.h
//  musubi
//
//  Created by MokaFive User on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MIdentity;

@interface MSignatureUserKey : NSManagedObject

@property (nonatomic, retain) NSData * key;
@property (nonatomic) int64_t period;
@property (nonatomic, retain) MIdentity *identity;

@end
