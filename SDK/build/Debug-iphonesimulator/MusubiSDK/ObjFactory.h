//
//  ObjFactory.h
//  musubi
//
//  Created by Willem Bult on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Obj,MObj;

@interface ObjFactory : NSObject

+ (Obj*) objFromManagedObj: (MObj*) mObj;

@end
