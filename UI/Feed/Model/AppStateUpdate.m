//
//  AppStateUpdate.m
//  musubi
//
//  Created by Willem Bult on 11/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppStateUpdate.h"

@implementation AppStateUpdate

@synthesize obj;

+ (id)createFromObj:(Obj *)obj {
    id update = [[[AppStateUpdate alloc] init] autorelease];
    [update setObj: obj];
    return update;
}

@end
