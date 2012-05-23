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
//  MIdentity.m
//  Musubi
//
//  Created by Willem Bult on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MIdentity.h"


@implementation MIdentity

@dynamic blocked;
@dynamic claimed;
@dynamic contactId;
@dynamic createdAt;
@dynamic musubiName;
@dynamic musubiThumbnail;
@dynamic name;
@dynamic nextSequenceNumber;
@dynamic owned;
@dynamic principal;
@dynamic principalHash;
@dynamic principalShortHash;
@dynamic receivedProfileVersion;
@dynamic sentProfileVersion;
@dynamic thumbnail;
@dynamic type;
@dynamic updatedAt;
@dynamic whitelisted;

- (NSString *)displayName {
    if (self.name != nil) {
        return self.name;
    } else if (self.principal != nil) {
        return self.principal;
    } else {
        return @"Unknown";
    }
}
@end
