//
//  Update.h
//  musubi
//
//  Created by Willem Bult on 11/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Obj.h"

@protocol Update <NSObject>

- (Obj*) obj;
+ (id)createFromObj:(Obj *)obj;

@end
