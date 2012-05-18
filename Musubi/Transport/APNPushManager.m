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
//  APNPushManager.m
//  musubi
//
//  Created by MokaFive User on 5/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "APNPushManager.h"

@implementation APNPushManager
+ (void) registerDevice:(NSString*)deviceToken identities:(NSArray*)idents {
    NSMutableDictionary* registrationRequest = [[NSMutableDictionary alloc] init];
    [registrationRequest setValue:idents forKey:@"identityExchanges"];
    [registrationRequest setValue:deviceToken forKey:@"deviceToken"];
#ifdef DEBUG
    BOOL production = NO;
#else
    BOOL production = YES;
#endif
    [registrationRequest setValue:[NSNumber numberWithBool:production] forKey:@"production"];
    NSError* error = nil;
    NSData* body = [NSJSONSerialization dataWithJSONObject:registrationRequest options:0 error:&error];
    if(!body) {
        NSLog(@"Failed to serialize json for registration %@", error);
    } else {
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:@"http://bumblebee.musubi.us:6253/api/0/register"]];
        [request setHTTPMethod:@"POST"];
        [request setValue:[NSString stringWithFormat:@"%u", body.length] forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:body];
        NSURLResponse* response;
        NSError* error = nil;
        
        //Capturing server response
        NSData* result = [NSURLConnection sendSynchronousRequest:request  returningResponse:&response error:&error];
        
        if(result) {
            NSLog(@"Registration returned %@", [[NSString alloc] initWithData:result encoding:NSUnicodeStringEncoding]);
        }
        
        [TestFlight passCheckpoint:@"[AMQPListener] registered at push server"];
    }
}

+ (void) clearUnread:(NSString*)deviceToken {
    NSMutableDictionary* registrationRequest = [[NSMutableDictionary alloc] init];
    [registrationRequest setValue:deviceToken forKey:@"identityExchanges"];
    [registrationRequest setValue:deviceToken forKey:@"deviceToken"];
    NSError* error = nil;
    NSData* body = [deviceToken dataUsingEncoding:NSUnicodeStringEncoding];
    if(!body) {
        NSLog(@"Failed to serialize device token for clearing unread %@", error);
    } else {
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:@"http://bumblebee.musubi.us:6253/api/0/clearunread"]];
        [request setHTTPMethod:@"POST"];
        [request setValue:[NSString stringWithFormat:@"%u", body.length] forHTTPHeaderField:@"Content-Length"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:body];
        NSURLResponse* response;
        NSError* error = nil;
        
        //Capturing server response
        NSData* result = [NSURLConnection sendSynchronousRequest:request  returningResponse:&response error:&error];
        
        if(result) {
            NSLog(@"Clear returned %@", [[NSString alloc] initWithData:result encoding:NSUnicodeStringEncoding]);
        }
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
        });
        [TestFlight passCheckpoint:@"[AMQPListener] cleared unread"];
    }
}


@end
