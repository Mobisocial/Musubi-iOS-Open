//
//  NSDate+LocalTime.h
//  musubi
//
//  Created by MokaFive User on 6/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (LocalTime)
-(NSDate *) toLocalTime;
-(NSDate *) toGlobalTime;
@end
