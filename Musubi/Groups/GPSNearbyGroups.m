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

@synthesize locationCtrl;

- (id)init {
    self = [super init];
    if (self != nil) {
        locationCtrl = [LocationController sharedInstance];
    }
    return self;
}

- (void)updatedLocation:(CLLocation *)location {
    
}

- (NSArray*) findNearbyGroups {
    return [self findGroupsNear:[locationCtrl location] withPassword:nil];
}

- (NSArray*) findGroupsNear: (CLLocation*) loc withPassword: (NSString*) pwd {
    NSString* url = @"http://suif.stanford.edu/dungbeetle/nearby.php";

    NSMutableString *body = [[[NSMutableString alloc] init] autorelease];   
    [body appendFormat:@"lat=%f", [loc coordinate].latitude];
    [body appendFormat:@"&lng=%f", [loc coordinate].longitude];
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
            Group* group = [[[Group alloc] initWithName:[dict valueForKey:@"group_name"] feedUri: [NSURL URLWithString:[dict valueForKey:@"feed_uri"]]] autorelease];
            [groups addObject:group];
        }
        
        return groups;
    }
    
    return nil;
}

@end
