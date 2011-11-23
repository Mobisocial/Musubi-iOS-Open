//
//  AppStateUpdate.h
//  musubi
//
//  Created by Willem Bult on 11/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Update.h"

static NSString* kObjTypeAppState = @"appstate";

@interface AppStateUpdate : NSObject<Update> {
    Obj* obj;
}

@property (nonatomic,retain) Obj* obj;

+ (id) createFromObj: (Obj*) obj;

@end
