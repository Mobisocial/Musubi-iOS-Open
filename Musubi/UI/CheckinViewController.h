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
//  CheckinViewController.h
//  musubi
//
//  Created by Ian Vo on 7/5/12.
//  Copyright (c) 2012 Stanford University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Three20/Three20.h"
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "GpsLookup.h"

@class MFeed, StatusTextView;


@protocol CheckinViewControllerDelegate
- (void) reloadFeed;
@end

@interface CheckinViewController : UIViewController <UIGestureRecognizerDelegate, UITextViewDelegate, MKMapViewDelegate> {
    
    IBOutlet TTView* postView;
    IBOutlet TTButton* sendButton;
    IBOutlet StatusTextView* statusField;
    GpsLookup* lookup;
    NSNumber *lat, *lon;
}

@property (nonatomic, retain) MFeed* feed;
@property (strong, nonatomic) IBOutlet MKMapView *mapView;

@property (nonatomic, weak) id<CheckinViewControllerDelegate> delegate;

@end