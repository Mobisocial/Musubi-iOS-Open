
//
//  LocationController.h
//  musubi
//
//  Created by Willem Bult on 10/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol LocationControllerDelegate <NSObject>
@required

- (void) updatedLocation: (CLLocation*) location;

@end

@interface LocationController : NSObject <CLLocationManagerDelegate> {
    
	CLLocationManager* locationManager;
	CLLocation* location;
	id delegate;
}

@property (nonatomic, retain) CLLocationManager* locationManager;
@property (nonatomic, retain) CLLocation* location;
@property (nonatomic, assign) id <LocationControllerDelegate> delegate;

+ (LocationController*) sharedInstance;

@end