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
//  FeedManager.m
//  Musubi
//
//  Created by Willem Bult on 3/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeedManager.h"
#import "NSData+Crypto.h"

@implementation FeedManager

- (id)initWithStore:(PersistentModelStore *)s {
    self = [super initWithEntityName:@"Feed" andStore:s];
    if (self != nil) {
    }
    return self;
}

+ (NSData*) fixedIdentifierForIdentities: (NSArray*) identities {
    NSComparisonResult (^comparator)(id ident1, id ident2) =  ^(id ident1, id ident2) {
        if (((MIdentity*) ident1).type < ((MIdentity*) ident2).type) {
            return -1;
        } else if (((MIdentity*) ident1).type > ((MIdentity*) ident2).type) {
            return 1;
        } else {
            return [[[((MIdentity*) ident1) principalHash] hex] compare:[[((MIdentity*) ident2) principalHash] hex]];
        }
    };
    
    uint16_t lastType = 0;
    NSData* lastHash = [NSData data];
    NSMutableData* hashData = [NSMutableData data];
    for (MIdentity* ident in [identities sortedArrayUsingComparator:comparator]) {
        short type = ident.type;
        NSData* hash = ident.principalHash;
        
        if (type == lastType && [hash isEqualToData:lastHash])
            continue;
        
        [hashData appendBytes: &type length:1];
        [hashData appendData: hash];
    }
    
    return [hashData sha256Digest];
}


@end
