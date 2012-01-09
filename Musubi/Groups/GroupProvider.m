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
//  GroupProvider.m
//  musubi
//
//  Created by Willem Bult on 10/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GroupProvider.h"

static const UInt8 publicKeyIdentifier[] = "edu.stanford.mobisocial.musibi\0";
static const UInt8 privateKeyIdentifier[] = "edu.stanford.mobisocial.musubi\0";

@implementation GroupProvider

- (NSString*) sessionURIForGroup: (NSString*) group andSession: (NSString*) session {
    
    NSData* key = [NSData generateSecureRandomKeyOf:16];
    NSString* base64Key = [key encodeBase64];

    NSMutableDictionary* queryComponents = [NSMutableDictionary dictionaryWithCapacity:3];
    [queryComponents setObject:group forKey:@"groupName"];
    [queryComponents setObject:session forKey:@"session"];
    [queryComponents setObject:base64Key forKey:@"key"];

    NSString* url = [NSString stringWithFormat: @"http://suif.stanford.edu/dungbeetle/index.php?%@", [queryComponents stringFromQueryComponents]];

    return url;
}

- (void)updateGroup: (Feed*) group sinceVersion: (int) version {
    NSData* key = [[group key] decodeBase64];
    
    NSString* session = [group session];
    NSString* pubKeyB64 = [[Identity sharedInstance] publicKeyBase64];
    NSString* email = [[Identity sharedInstance] email];
    NSURL* url = [NSURL URLWithString:@"http://suif.stanford.edu/dungbeetle/index.php"];
    
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithCapacity:4];
    [params setObject:session forKey:@"session"];
    [params setObject:[self encryptAndBase64:pubKeyB64 withKey:key] forKey:@"public_key"];
    [params setObject:[self encryptAndBase64:email withKey:key] forKey:@"email"];
    [params setObject:[NSString stringWithFormat:@"%d", version] forKey:@"version"];
    NSString* body = [params stringFromQueryComponents];
    
    NSMutableURLRequest* req = [[[NSMutableURLRequest alloc] initWithURL:url] autorelease];
    [req setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-length"];
    [req setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPMethod:@"POST"];
    
    NSHTTPURLResponse *urlResponse = nil;
    NSError *error = [[NSError alloc] init];
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:req
                                                 returningResponse:&urlResponse 
                                                             error:&error];
    
    if ([urlResponse statusCode] >=200 && [urlResponse statusCode] <300)
    {
        // construct groups from JSON response
        SBJsonParser* parser = [[[SBJsonParser alloc] init] autorelease];
        NSDictionary* groupJSON = [parser objectWithData: responseData];
        
        NSMutableArray* members = [NSMutableArray array];
        for (NSString* userJSON in [parser objectWithString: [groupJSON objectForKey:@"users"]]) {
            NSDictionary* userDict = [parser objectWithString: userJSON];
            NSString* pubK = [self decryptAndDecodeBase64:[userDict objectForKey:@"public_key"] withKey:key];
            NSString* email = [self decryptAndDecodeBase64:[userDict objectForKey:@"email"] withKey:key];
            
            if (!(pubK == nil || [pubK isEqualToString:@""])) {
                User* member = [[[User alloc] init] autorelease];
                [member setName: email];
                [member setId: pubK];
                [members addObject:member];
            }
        }
        
        [group setMembers:members];
    }
}

- (NSString*) decryptAndDecodeBase64: (NSString*) str withKey: (NSData*) key {
    if (str == (id)[NSNull null]) {
        return nil;
    }
    NSData* decrypted = [[str decodeBase64] decryptWithAES128ECBPKCS7WithKey:key];
    return [[[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding] autorelease];
}

- (NSString*) encryptAndBase64: (NSString*) str withKey: (NSData*) key {
    NSData* encrypted = [[str dataUsingEncoding:NSUTF8StringEncoding] encryptWithAES128ECBPKCS7WithKey:key];
    return [encrypted encodeBase64];
}

- (void)refreshGroupList {
}

@end
