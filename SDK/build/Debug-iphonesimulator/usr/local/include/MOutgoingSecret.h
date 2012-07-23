//
//  MOutgoingSecret.h
//  musubi
//
//  Created by MokaFive User on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MIdentity;

@interface MOutgoingSecret : NSManagedObject

@property (nonatomic, retain) NSData * encryptedKey;
@property (nonatomic) int64_t encryptionPeriod;
@property (nonatomic, retain) NSData * key;
@property (nonatomic, retain) NSData * signature;
@property (nonatomic) int64_t signaturePeriod;
@property (nonatomic, retain) MIdentity *myIdentity;
@property (nonatomic, retain) MIdentity *otherIdentity;

@end
