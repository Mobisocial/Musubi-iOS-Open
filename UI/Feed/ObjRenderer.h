//
//  ObjRenderer.h
//  musubi
//
//  Created by Willem Bult on 11/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Obj.h"
#import "Update.h"

@interface ObjRenderer : NSObject

- (UIView*) renderUpdate: (id<Update>) update;
- (int) renderHeightForUpdate: (id<Update>) update;

@end
