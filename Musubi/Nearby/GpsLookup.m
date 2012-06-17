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
//  GpsLookup.m
//  musubi
//
//  Created by T.J. Purtell on 6/17/12.
//  Copyright (c) 2012 Stanford MobiSocial Labratory. All rights reserved.
//

#import "GpsLookup.h"

@implementation GpsLookup
@synthesize locationManager, successCallback, failCallback;

- (id)init
{
    self = [super init];
    if (!self)
        return nil;

    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    [locationManager startUpdatingLocation];
    
    return self;
}
- (void)lookupAndCall:(void (^)(CLLocation *))success orFail:(void (^)(NSError *))fail 
{
    assert(!successCallback);
    assert(!failCallback);
    
    success = successCallback;
    fail = failCallback;
    
    [locationManager startUpdatingLocation];
}
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    
}
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
    
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    failCallback(error);
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region
{
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [locationManager stopUpdatingLocation];
    successCallback(newLocation);
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    
}


@end
