//
//  StatusUpdate.h
//  musubi
//
//  Created by Willem Bult on 10/30/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Obj.h"
#import "Update.h"

static NSString* kObjTypeStatus = @"status";

@interface StatusUpdate : NSObject<Update> {
    NSString* text;
}

@property (nonatomic,retain) NSString* text;

- (id) initWithText:(NSString *)t;
- (Obj*) obj;
+ (id) createFromObj: (Obj*) obj;

@end
