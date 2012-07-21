/*
 * Copyright 2012 The Stanford MobiSocial Laboratory
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */




//
//  ObjFactory.m
//  musubi
//
//  Created by Willem Bult on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ObjFactory.h"
#import "MObj.h"
#import "Obj.h"
#import "SBJsonParser.h"

#import "StatusObj.h"
#import "IntroductionObj.h"
#import "PictureObj.h"
#import "LikeObj.h"
#import "DeleteObj.h"
#import "FileObj.h"
#import "UnknownObj.h"
#import "JoinRequestObj.h"

@implementation ObjFactory

+ (Obj*) objFromManagedObj: (MObj*) mObj {
    assert (mObj != nil);    
    
    
    NSDictionary* data = nil;
    if (mObj.json) {
        SBJsonParser* parser = [[SBJsonParser alloc] init];
        data = [parser objectWithString:mObj.json];
    }
    
    NSString* objType = mObj.type;
    if ([objType isEqualToString:kObjTypeStatus]) {
        return [[StatusObj alloc] initWithData:data];
    } else if ([objType isEqualToString:kObjTypeIntroduction]) {
        return [[IntroductionObj alloc] initWithData:data];
    } else if ([objType isEqualToString:kObjTypeJoinRequest]) {
        return [[JoinRequestObj alloc] initWithData:data];
    } else if ([objType isEqualToString:kObjTypePicture]) {
        return [[PictureObj alloc] initWithRaw:mObj.raw andData:data];
    } else if ([objType isEqualToString:kObjTypeLike]) {
        return [[LikeObj alloc] initWithData:data];
    } else if ([objType isEqualToString:kObjTypeDelete]) {
        return [[DeleteObj alloc] initWithData:data];
    } else if ([objType isEqualToString:kObjTypeFile]) {
        return [[FileObj alloc] initWithType:objType data:data andRaw:mObj.raw];
    }
    
    return [[UnknownObj alloc] initWithType:objType data:data andRaw:mObj.raw];
}

@end
