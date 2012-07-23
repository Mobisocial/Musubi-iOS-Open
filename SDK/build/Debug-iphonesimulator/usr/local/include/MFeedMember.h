//
//  MFeedMember.h
//  musubi
//
//  Created by MokaFive User on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MFeed, MIdentity;

@interface MFeedMember : NSManagedObject

@property (nonatomic, retain) MFeed *feed;
@property (nonatomic, retain) MIdentity *identity;

@end
