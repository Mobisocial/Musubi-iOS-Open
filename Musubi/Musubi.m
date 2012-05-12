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
//  Musubi.m
//  musubi
//
//  Created by Willem Bult on 10/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Musubi.h"

#import "NSData+Crypto.h"
#import "NSData+Base64.h"

#import "UnverifiedIdentityProvider.h"
#import "AphidIdentityProvider.h"

#import "IBEncryptionScheme.h"

#import "MessageEncoder.h"
#import "MessageEncodeService.h"
#import "MessageDecodeService.h"
#import "AMQPTransport.h"
#import "FacebookIdentityUpdater.h"
#import "GoogleIdentityUpdater.h"
#import "ObjPipelineService.h"

#import "PersistentModelStore.h"
#import "FeedManager.h"
#import "AccountManager.h"
#import "IdentityManager.h"
#import "IdentityKeyManager.h"
#import "TransportManager.h"
#import "MApp.h"
#import "MFeed.h"
#import "MIdentity.h"

#import "IntroductionObj.h"
#import "Authorities.h"

#include "ibecrypt.h"
#include <stdio.h>

static char* HEX_LOOKUP = "0123456789ABCDEF";
char* hexstring(char* data, int length) {
    char* hex = malloc(length * 2 + 1);
    for(int i = 0; i < length; ++i) {
        hex[2 * i + 0] = HEX_LOOKUP[data[i] & 0xF];
        hex[2 * i + 1] = HEX_LOOKUP[(data[i] >> 4) & 0xF];
    }
    hex[2 * length] = 0;
    return hex;
}

int testme(){
    printf("generating parameters\n");
    char* mk_data = NULL;
    int mk_length = 0;
    ibecrypto_public_parameters* pp = NULL;
    pp = ibecrypto_global_public_parameters(&mk_data, &mk_length);
    
    element_t mk;
    element_init_Zr(mk, pp->pairing);
    element_from_bytes(mk, mk_data);
    element_printf("master key = %B\n", mk);
    element_clear(mk);
    
    printf("serializing and deserializing\n");
    char* pp_data = NULL;
    int pp_length = 0;
    ibecrypto_serialize_parameters(&pp_data, &pp_length, pp);
    ibecrypto_clear_public_parameters(pp);
    pp = ibecrypto_unserialize_parameters(pp_data, pp_length);
    
    char* uid_data = "frank";
    int uid_length = strlen(uid_data);
    
    printf("computing personal key\n");
    char* uk_data = NULL;
    int uk_length = 0;
    ibecrypto_keygen(&uk_data, &uk_length, pp, mk_data, mk_length, uid_data, uid_length);
    
    //deserialize the user secret
    element_t d0, d1;
    element_init_G2(d0, pp->pairing);
    element_init_G2(d1, pp->pairing);
    element_from_bytes_compressed(d0, (unsigned char*)uk_data);
    element_from_bytes_compressed(d1, (unsigned char*)uk_data + element_length_in_bytes_compressed(d0));
    element_printf("user key = %B, %B\n", d0, d1);
    element_clear(d0);
    element_clear(d1);
    
    
    printf("generating encrypting a key for a communication\n");
    char* encrypted_key_data = NULL;
    int encrypted_key_length = 0;
    char* key_data = NULL;
    int key_length = 0;
    ibecrypto_encrypt(&encrypted_key_data, &encrypted_key_length, &key_data, &key_length, pp, uid_data, uid_length);
    
    //deserialize the encrypted key
    element_t c0, c1;
    element_init_G1(c0, pp->pairing);
    element_init_G1(c1, pp->pairing);
    element_from_bytes_compressed(c0, (unsigned char*)encrypted_key_data);
    element_from_bytes_compressed(c1, (unsigned char*)encrypted_key_data + element_length_in_bytes_compressed(c0));
    element_printf("encrypted key = %B, %B\n", c0, c1);
    element_clear(c0);
    element_clear(c1);
    
    char* key_string = hexstring(key_data, key_length);
    printf("key = %s\n", key_string);
    free(key_string);
    
    printf("decrypting a key for a communication\n");
    char* decrypted_key_data = NULL;
    int decrypted_key_length = 0;
    ibecrypto_decrypt(&decrypted_key_data, &decrypted_key_length, pp, uk_data, uk_length, encrypted_key_data, encrypted_key_length);
    
    key_string = hexstring(decrypted_key_data, decrypted_key_length);
    printf("decrypted key = %s\n", key_string);
    free(key_string);
    
    if(key_length != decrypted_key_length || memcmp(key_data, decrypted_key_data, key_length)) 
    {
        printf("decryption failed! (bad)\n");
    } else {
        printf("decryption successful (good)\n");
    }
    
    free(decrypted_key_data);
    encrypted_key_data[sizeof(void*)]++;
    printf("decrypting a corrupted key for a communication\n");
    ibecrypto_decrypt(&decrypted_key_data, &decrypted_key_length, pp, uk_data, uk_length, encrypted_key_data, encrypted_key_length);
    
    key_string = hexstring(decrypted_key_data, decrypted_key_length);
    printf("corrupted decrypted key = %s\n", key_string);
    free(key_string);
    
    if(key_length != decrypted_key_length || memcmp(key_data, decrypted_key_data, key_length)) 
    {
        printf("decryption failed! (good)\n");
    } else {
        printf("decryption successful (bad)\n");
    }
    free(decrypted_key_data);
    
    free(key_data);
    free(encrypted_key_data);
    ibecrypto_clear_public_parameters(pp);
    
	return 1;
}


@implementation Musubi

static Musubi* _sharedInstance = nil;

@synthesize mainStore, storeFactory, notificationCenter, keyManager, encodeService, decodeService, transport, objPipelineService, apnDeviceToken;

+(Musubi*)sharedInstance
{
	@synchronized([Musubi class])
	{
		if (!_sharedInstance) {
            //testme();
			[[self alloc] init];
        }
        
		return _sharedInstance;
	}
    
	return nil;
}

+(id)alloc
{
	@synchronized([Musubi class])
	{
		NSAssert(_sharedInstance == nil, @"Attempted to allocate a second instance of a singleton.");
		_sharedInstance = [super alloc];
		return _sharedInstance;
	}
    
	return nil;
}

- (id)init {
    self = [super init];
    
    if (self == nil) 
        return self;
    
      
    // The store factory creates stores for other threads, the main store is used on the main thread
    self.storeFactory = [PersistentModelStoreFactory sharedInstance];
    self.mainStore = storeFactory.rootStore;
    
    // The notification sender informs every major part in the system about what's going on
    self.notificationCenter = [[NSNotificationCenter alloc] init];
            
    [self performSelectorInBackground:@selector(setup) withObject:nil];
   
    return self;
}

- (void) setup {    
       
    // The identity provider is our main IBE point of contact
    identityProvider = [[AphidIdentityProvider alloc] init];
        
    // The key manager handles our encryption and signature keys
    self.keyManager = [[IdentityKeyManager alloc] initWithIdentityProvider: identityProvider];
    
    // The encoding service encodes all our messages, to be picked up by the transport
    self.encodeService = [[MessageEncodeService alloc] initWithStoreFactory: storeFactory andIdentityProvider:identityProvider];
    
    // The decoding service decodes incoming encoded messages
    self.decodeService = [[MessageDecodeService alloc] initWithStoreFactory: storeFactory andIdentityProvider:identityProvider];
    
    // The transport sends and receives raw data from the network
    self.transport = [[AMQPTransport alloc] initWithStoreFactory:storeFactory];
    [transport start];
    
    // The obj pipeline will process our objs so we can render them
    self.objPipelineService = [[ObjPipelineService alloc] initWithStoreFactory: storeFactory];
    
    // Make sure we keep the facebook friends up to date
    FacebookIdentityUpdater* facebookUpdater = [[FacebookIdentityUpdater alloc] initWithStoreFactory: storeFactory];
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:kFacebookIdentityUpdaterFrequency target:facebookUpdater selector:@selector(refreshFriendsIfNeeded) userInfo:nil repeats:YES] forMode:NSDefaultRunLoopMode];

    GoogleIdentityUpdater* googleUpdater = [[GoogleIdentityUpdater alloc] initWithStoreFactory: storeFactory];
    [[NSRunLoop mainRunLoop] addTimer:[NSTimer timerWithTimeInterval:kGoogleIdentityUpdaterFrequency target:googleUpdater selector:@selector(refreshFriendsIfNeeded) userInfo:nil repeats:YES] forMode:NSDefaultRunLoopMode];
    
    [TestFlight passCheckpoint:@"[Musubi] launched"];

}


- (PersistentModelStore *) newStore {
    return [storeFactory newStore];
}


@end
