//
//  StatusUpdate.m
//  musubi
//
//  Created by Willem Bult on 10/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "StatusUpdate.h"

@implementation StatusUpdate

@synthesize text;

- (id)initWithText:(NSString *)t {
    
    self = [super init];
    if (self != nil) {
        self.text = t;
    }
    
    return self;
}

- (Obj*) obj {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    [dict setObject: text forKey: @"text"];
    
    Obj* obj = [[[Obj alloc] initWithType: kObjTypeStatus] autorelease];
    [obj setData: dict];
    return obj;
}

+ (id)createFromObj:(Obj *)obj {
    return [[[StatusUpdate alloc] initWithText: [[obj data] objectForKey:@"text"]] autorelease];
}

@end
