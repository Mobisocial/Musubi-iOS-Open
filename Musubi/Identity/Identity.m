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
        NSString* privKeyB64 = @"MIICXQIBAAKBgQCqEnUVom64ZzTupLcrBllqZnKlkMxV+nH9Mg78Jqo2OG5Xv7fq0RQIh3Nuis4Wq1zFIG+CNbRjB76zRKP1Dr635N9GTjiTFmnDwTKDwfotwpuJTNaZmowh92xNR+pFYtoCPZQ3ZlUd/qGYPLI4RsQZOXq3SpRdc0kMxpKUEtUCqwIDAQABAoGAKJjXUh7AB0y7meu/vYl6dqeV3me+Hxf1ddcpNI+WOfMmg9PD902JVq/eohiIMWkeb//aHl7rfGgw4WIVMT4f0Co3ju5KxuJnJtE4WA/Iut6/iR4UATX2Z8O8OfcioUtW+F7IEE64/9d0wW7wn177vsqUbC6Q3o8Ay+ljTNRFDAECQQDR+eCbBJSLq9374Iszz/Ru4xhIcM76RDdH3RrgmeC37F8xBuC5mn0yiiUDqZIjLwOTed/PjjzoCAp16L1SewiBAkEAz1l/hmcpdkk7+IVVThH2LWOctzTGu2LbRLwSeKZ2HMCsUK9kDDVh4txUEg23fcu2LMp3vAFD07mINAGlJHgVKwJBAK2jGDS49eoGZxxqFFL1TeoAy8zj1JUqohhAZICFX0pZImLVkDKL6apIiNFdgaassyVabFUkB4PNWnEk1KKHcYECQCAbV6fUKZNrW6Hr432nQltc5VNpFKzHbfSCusl73SYun4AO6IsLaRDb1RjGjvcnqBnfcBLojzwlqnWDG7M99OkCQQDJozXppqMj5HqCEGUOHGGxHigHAHCCC15vR2e9k84goUNbf9E7ICyII+ms2zpk0rIj+VtCvGWmC7WXUaowu62P";
        
        NSString* pubKeyB64 = @"MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCqEnUVom64ZzTupLcrBllqZnKlkMxV+nH9Mg78Jqo2OG5Xv7fq0RQIh3Nuis4Wq1zFIG+CNbRjB76zRKP1Dr635N9GTjiTFmnDwTKDwfotwpuJTNaZmowh92xNR+pFYtoCPZQ3ZlUd/qGYPLI4RsQZOXq3SpRdc0kMxpKUEtUCqwIDAQAB";
        
        OpenSSLPrivateKey* privKey = [[[OpenSSLPrivateKey alloc] initWithDER: [privKeyB64 decodeBase64]] autorelease];
        OpenSSLPublicKey* pubKey = [[[OpenSSLPublicKey alloc] initWithEncoded: [pubKeyB64 decodeBase64]] autorelease];
        [self setKeyPair: [[[OpenSSLKeyPair alloc] initWithPrivateKey:privKey andPublicKey:pubKey] autorelease]];
//		[self setKeyPair: [OpenSSLKeyPair keyPairWithLength:1024]];
        
        NSLog(@"Private key: %@", [[[[self keyPair] privateKey] der] encodeBase64]);
        NSLog(@"Public key: %@", [[[[self keyPair] publicKey] encoded] encodeBase64]);
        [self setEmail:@"Willem_iPhone@mobisocial.stanford.edu"];
	}
    
	return self;
}

- (NSString *)publicKeyBase64 {
    return [[[[self keyPair] publicKey] encoded] encodeBase64];
}


@end
