
//
//  LocationController.m
//  musubi
//
//  Created by Willem Bult on 10/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "LocationController.h"

static LocationController* sharedInstance = nil;

@implementation LocationController
@synthesize locationManager, location, delegate;

- (id)init
{
 	self = [super init];
	if (self != nil) {
        [self setLocationManager: [[CLLocationManager alloc] init]];
        [[self locationManager] setDelegate: self];
        [[self locationManager] setDesiredAccuracy:kCLLocationAccuracyBest];
        
//        [self.locationManager startUpdatingLocation];
        [self setLocation: [[CLLocation alloc] initWithLatitude:37.429717 longitude:-122.173269]];
//        [self setLocation: [[[CLLocation alloc] initWithLatitude:37.778788 longitude:-122.411406] autorelease]];

	}
	return self;
}


#pragma mark -
#pragma mark CLLocationManagerDelegate Methods
- (void)locationManager:(CLLocationManager*)manager
	didUpdateToLocation:(CLLocation*)newLocation
		   fromLocation:(CLLocation*)oldLocation
{
    [self setLocation:newLocation];
}

- (void)locationManager:(CLLocationManager*)manager
	   didFailWithError:(NSError*)error
{
    /* ... */
    
}

#pragma mark -
#pragma mark Singleton Object Methods

+ (LocationController*) sharedInstance {
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [[self alloc] init];
        }
    }
    return sharedInstance;
}

@end