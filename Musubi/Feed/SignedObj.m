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
//  SignedObj.m
//  musubi
//
//  Created by Willem Bult on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SignedObj.h"
#import "JoinNotificationObj.h"
#import "StatusObj.h"
#import "PictureObj.h"
#import "NSData+Base64.h"

@implementation SignedObj

@synthesize timestamp, senderPublicKey;


+ (SignedObj *)readFromJSON:(NSDictionary *)json {
    NSString* type = [json objectForKey:@"type"];
    SignedObj* obj = nil;
    
    if ([type isEqualToString:kObjTypeJoinNotification]) {
        obj = [[[JoinNotificationObj alloc] initWithURI:[json objectForKey:@"uri"]] autorelease];
    } else if ([type isEqualToString:kObjTypeStatus]) {
        obj = [[[StatusObj alloc] initWithText:[json objectForKey:@"text"]] autorelease];
    } else if ([type isEqualToString:kObjTypePicture]) {
        obj = [[[PictureObj alloc] initWithData:[[json objectForKey:@"data"] decodeBase64]] autorelease];
    }
    
    return obj;
}

@end
