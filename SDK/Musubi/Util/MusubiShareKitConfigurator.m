


//
//  MusubiShareKitConfigurator.m
//  musubi
//
//  Created by Ben Dodson on 6/29/12.
//  Copyright (c) 2012 Stanford University. All rights reserved.
//

#import "MusubiShareKitConfigurator.h"
#import "FacebookAuth.h"

@implementation MusubiShareKitConfigurator

- (NSString*)appName {
	return @"Musubi";
}

- (NSString*)appURL {
	return @"http://musubi.us";
}

- (NSString*)facebookAppId {
	return kFacebookAppId;
}

@end
