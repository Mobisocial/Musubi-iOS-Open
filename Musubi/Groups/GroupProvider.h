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
//  GroupProvider.h
//  musubi
//
//  Created by Willem Bult on 10/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>
#import "ObjectStore.h"
#import "NSData+Crypto.h"
#import "SBJsonParser.h"
#import "Feed.h"
#import "User.h"
#import "XQueryComponents.h"
#import "NSData+Base64.h"
#import "OpenSSLKey.h"
#import "Identity.h"

@interface GroupProvider : NSObject {
}

- (void)updateGroup: (Feed*) group sinceVersion: (int) version;
- (NSString*) encryptAndBase64: (NSString*) str withKey: (NSData*) key;
- (NSString*) decryptAndDecodeBase64: (NSString*) str withKey: (NSData*) key;

@end
