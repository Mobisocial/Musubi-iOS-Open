//
//  DeleteObj.h
//  musubi
//
//  Created by Ben Dodson on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Obj.h"

#define kObjTypeDelete @"delete"
#define kObjFieldHashes @"hashes"

@interface DeleteObj : Obj

- (id) initWithData: (NSDictionary*) data;
- (id) initWithTargetObj: (MObj*) obj;

@end
