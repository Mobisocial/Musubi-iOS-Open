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
//  Identity.m
//  musubi
//
//  Created by Willem Bult on 10/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Identity.h"

@implementation Identity
static Identity* _sharedInstance = nil;

@synthesize keyPair, email;

+(Identity*)sharedInstance
{
	@synchronized([Identity class])
	{
		if (!_sharedInstance)
			[[self alloc] init];
        
		return _sharedInstance;
	}
    
	return nil;
}

+(id)alloc
{
	@synchronized([Identity class])
	{
		NSAssert(_sharedInstance == nil, @"Attempted to allocate a second instance of a singleton.");
		_sharedInstance = [super alloc];
		return _sharedInstance;
	}
    
	return nil;
}

-(id)init {
	self = [super init];
	if (self != nil) {
        
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        NSData* publicKey = [defaults objectForKey:@"publicKey"];
        NSData* privateKey = [defaults objectForKey:@"privateKey"];
        
        if (publicKey != nil && privateKey != nil) {
            OpenSSLPublicKey* pubKey = [[[OpenSSLPublicKey alloc] initWithEncoded:publicKey] autorelease];
            OpenSSLPrivateKey* privKey = [[[OpenSSLPrivateKey alloc] initWithDER:privateKey] autorelease];
            [self setKeyPair: [[[OpenSSLKeyPair alloc] initWithPrivateKey:privKey andPublicKey:pubKey] autorelease]];
        } else {
            [self setKeyPair: [OpenSSLKeyPair keyPairWithLength:1024]];
            
            publicKey = [[keyPair publicKey] encoded];
            privateKey = [[keyPair privateKey] der];
            
            [defaults setObject:publicKey forKey:@"publicKey"];
            [defaults setObject:privateKey forKey:@"privateKey"];
            [defaults synchronize];
        }
        
        NSLog(@"Private key: %@", [[[[self keyPair] privateKey] der] encodeBase64]);
        NSLog(@"Public key: %@", [[[[self keyPair] publicKey] encoded] encodeBase64]);
        [self setEmail:[UIDevice currentDevice].name];
	}
    
	return self;
}

- (NSString *)publicKeyBase64 {
    return [[[[self keyPair] publicKey] encoded] encodeBase64];
}

- (User *)user {
    User* user = [[[User alloc] init] autorelease];
    [user setName:email];
    [user setId: [self publicKeyBase64]];
    return user;
}

@end
