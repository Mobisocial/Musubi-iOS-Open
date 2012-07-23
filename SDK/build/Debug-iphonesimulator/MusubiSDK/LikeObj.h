//
//  LikeObj.h
//  musubi
//
//  Created by Ben Dodson on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Obj.h"

#define kObjTypeLike @"like_ref"

@interface LikeObj : Obj

- (id) initWithObjHash: (NSData*) hash;
- (id) initWithData: (NSDictionary*) data;

@end
