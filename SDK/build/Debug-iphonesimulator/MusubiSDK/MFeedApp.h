//
//  MFeedApp.h
//  musubi
//
//  Created by MokaFive User on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MApp, MFeed;

@interface MFeedApp : NSManagedObject

@property (nonatomic, retain) MApp *app;
@property (nonatomic, retain) MFeed *feed;

@end
