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
//  ProfileObj.m
//  musubi
//
//  Created by T.J. Purtell on 5/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ProfileObj.h"

#define kProfileObjReply @"reply"
#define kProfileObjVersion @"version"
#define kProfileObjName @"name"
#define kProfileObjPrincipal @"principal"

@implementation ProfileObj

- (id) initWithUser: (MIdentity*)user replyRequested:(BOOL)replyRequested includePrincipal:(BOOL)includePrincipal
{
    self = [super init];
    if (!self)
    return nil;

    NSMutableDictionary* profile = [NSMutableDictionary dictionaryWithCapacity:4];
    [profile setValue:[NSNumber numberWithBool:replyRequested] forKey:kProfileObjReply];
    [profile setValue:[NSNumber numberWithLongLong:(long long)([[NSDate date] timeIntervalSince1970] * 1000)] forKey:kProfileObjVersion];
    [profile setValue:user.musubiName forKey:kProfileObjName];
    if(includePrincipal) {
        [profile setValue:user.principal forKey:kProfileObjPrincipal];
    }

    self.data = profile;
    self.type = kObjTypeProfile;
    self.raw = user.musubiThumbnail;
    return self;
}
- (id) initRequest
{
    NSMutableDictionary* profile = [NSMutableDictionary dictionaryWithCapacity:4];
    [profile setValue:[NSNumber numberWithBool:YES] forKey:kProfileObjReply];
    self.data = profile;
    self.type = kObjTypeProfile;
    return self;
}
+ (void)handleFromSender:(MIdentity*)sender profileJson:(NSString*)json profileRaw:(NSData*)raw
{
    
}
@end
