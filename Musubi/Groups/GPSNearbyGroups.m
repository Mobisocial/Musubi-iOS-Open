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
//  GPSNearbyGroups.m
//  musubi
//
//  Created by Willem Bult on 10/10/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GPSNearbyGroups.h"
#import "SBJson.h"

@implementation GPSNearbyGroups

@synthesize locationCtrl, delegate;

- (id)init {
    self = [super init];
    if (self != nil) {
        locationCtrl = [LocationController sharedInstance];
        
        NSTimer* timer = [NSTimer timerWithTimeInterval:5 target:self selector:@selector(findGroups) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
    return self;
}

- (void) updatedLocation:(CLLocation*) location {
    [self findGroups];
}

- (void) findGroups {
    CLLocationCoordinate2D loc = [locationCtrl location].coordinate;
    NSString* pwd = nil;
    
    NSString* url = @"http://suif.stanford.edu/dungbeetle/nearby.php";

    NSMutableString *body = [[[NSMutableString alloc] init] autorelease];   
    [body appendFormat:@"lat=%f", loc.latitude];
    [body appendFormat:@"&lng=%f", loc.longitude];
    [body appendFormat:@"&password=%@", pwd != nil ? pwd : @""];
    
    NSMutableURLRequest* req = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
    [req setHTTPMethod:@"POST"];
    [req setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-length"];
    [req setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSHTTPURLResponse *urlResponse = nil;
    NSError *error = [[NSError alloc] init];
    
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:req
                                                 returningResponse:&urlResponse 
                                                             error:&error];
    
    if ([urlResponse statusCode] >=200 && [urlResponse statusCode] <300)
    {
        // construct groups from JSON response
        SBJsonParser* parser = [[[SBJsonParser alloc] init] autorelease];
        NSArray* json = [parser objectWithData: responseData];

        NSMutableArray* groups = [NSMutableArray arrayWithCapacity:[json count]];
        for (int i=0; i<[json count]; i++) {
            NSDictionary* dict = [parser objectWithString:[json objectAtIndex:i]];
            Feed* group = [Feed feedFromUri:[NSURL URLWithString:[dict valueForKey:@"feed_uri"]]];
            [groups addObject:group];
        }
        
        [delegate updatedGroups:groups];
    }
}


- (void)broadcastGroup: (Feed *) group during: (int) minutes withPassword: (NSString*) password {
    CLLocationCoordinate2D loc = [locationCtrl location].coordinate;
    
    NSMutableDictionary* queryComponents = [NSMutableDictionary dictionaryWithCapacity:3];
    [queryComponents setObject:group.name forKey:@"group_name"];
    [queryComponents setObject:[group uri] forKey:@"feed_uri"];
    [queryComponents setObject:[NSString stringWithFormat:@"%d", minutes] forKey:@"length"];
    [queryComponents setObject:[NSString stringWithFormat:@"%f", loc.latitude] forKey:@"lat"];
    [queryComponents setObject:[NSString stringWithFormat:@"%f", loc.longitude] forKey:@"lng"];    
    [queryComponents setObject:password forKey:@"password"];
    NSString* body = [queryComponents stringFromQueryComponents];
    
    NSURL* url = [NSURL URLWithString:@"http://suif.stanford.edu/dungbeetle/nearby.php"];
    NSMutableURLRequest* req = [[[NSMutableURLRequest alloc] initWithURL:url] autorelease];
    [req setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-length"];
    [req setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    [req setHTTPMethod:@"POST"];
    
    
    NSHTTPURLResponse *urlResponse = nil;
    NSError *error = [[NSError alloc] init];
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:req
                                                 returningResponse:&urlResponse 
                                                             error:&error];
    
    if ([urlResponse statusCode] >=200 && [urlResponse statusCode] <300) {
        NSString* str = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
        if (![str isEqualToString:@"1"]) {
            [[NSException exceptionWithName:@"Broadcast failed" reason:@"Could not broadcast group" userInfo:nil] raise];
        }
    }
}



@end
