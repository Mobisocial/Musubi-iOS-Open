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
//  MAccount.h
//  Musubi
//
//  Created by Willem Bult on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define kAccountNameProvisionalWhitelist @"provisional_whitelist"
#define kAccountNameLocalWhitelist @"local_whitelist"

#define kAccountTypeInternal @"mobisocial.musubi.internal"
#define kAccountTypeFacebook @"com.facebook.auth.login"
#define kAccountTypeGoogle @"com.google"

@class MFeed, MIdentity;

@interface MAccount : NSManagedObject

@property (nonatomic) NSString * name;
@property (nonatomic) NSString * type;
@property (nonatomic) MIdentity *identity;
@property (nonatomic) MFeed *feed;

@end
