//
//  StatusObj.h
//  musubi
//
//  Created by Willem Bult on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Obj.h"

#define kObjTypeStatus @"status"

@interface StatusObj : Obj<RenderableObj> 

@property (nonatomic, strong) NSString* text;

- (id) initWithText: (NSString*) text;
- (id) initWithData: (NSDictionary*) data;

@end
