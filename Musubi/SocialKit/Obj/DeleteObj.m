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
//  DeleteObj.m
//  musubi
//
//  Created by Ben Dodson on 5/14/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DeleteObj.h"
#import "ObjHelper.h"
#import "ObjManager.h"
#import "Musubi.h"
#import "NSData+HexString.h"
#import "MObj.h"

@implementation DeleteObj

- (id) initWithData: (NSDictionary*) data {
    self = [super initWithType:kObjTypeDelete data:data andRaw:nil];
    return self;
}

- (id) initWithTargetObj:(MObj *)obj {
    self = [super init];
    if (self) {
        [self setType: kObjTypeDelete];
        NSString* objHash = [obj.universalHash hexString];
        NSArray* deletion = [[NSArray alloc] initWithObjects:objHash, nil];
        [self setData: [NSDictionary dictionaryWithObjectsAndKeys:deletion, kObjFieldHashes, nil]];        
    }
    
    return self;
}

- (BOOL)processObjWithRecord:(MObj *)obj {
    NSArray *deletions = [self.data objectForKey: kObjFieldHashes];
    ObjManager* objMgr = [[ObjManager alloc] initWithStore: [[Musubi sharedInstance] newStore]];
    for (int i = 0; i < deletions.count; i++) {
        NSData* hashData = [[deletions objectAtIndex:i] dataFromHex];
        [objMgr deleteObjWithHash:hashData];
    }
    return NO;
}

@end
