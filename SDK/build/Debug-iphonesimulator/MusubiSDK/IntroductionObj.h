//
//  IntroductionObj.h
//  Musubi
//
//  Created by Willem Bult on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Obj.h"

#define kObjTypeIntroduction @"introduction"

@interface IntroductionObj : Obj<RenderableObj>

- (id) initWithIdentities: (NSArray*) ids;
- (id) initWithData: (NSDictionary*) data;

@end
