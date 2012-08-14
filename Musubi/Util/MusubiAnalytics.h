
//
//  MusubiAnalytics.h
//  musubi
//
//  Created by Ben Dodson on 7/22/12.
//  Copyright (c) 2012 Stanford University. All rights reserved.
//

#ifndef musubi_MusubiAnalytics_h
#define musubi_MusubiAnalytics_h

#import "GANTracker.h"

#define kAnalyticsPageAppEntryPoint @"/app_entry_point"
#define kAnalyticsPageEula @"/eula"
#define kAnalyticsPageFeedList @"/feed_list"
#define kAnalyticsPageFeed @"/feed"
#define kAnalyticsPageFeedGallery @"/feed_photo_gallery"

#define kAnalyticsCategoryApp @"App"
#define kAnalyticsActionSendObj @"Send Obj"
#define kAnalyticsActionFeedAction @"Feed Action"
#define kAnalyticsLabelFeedActionCamera @"Picture from Camera"
#define kAnalyticsLabelFeedActionGallery @"Picture from Gallery"
#define kAnalyticsLabelFeedActionRecordAudio @"Record Audio"
#define kAnalyticsLabelFeedActionSketch @"Sketch"
#define kAnalyticsLabelFeedActionCheckIn @"Check-In"

#define kAnalyticsActionInvite @"Invite"
#define kAnalyticsLabelYes @"Yes"
#define kAnalyticsLabelNo @"No"

#define kAnalyticsCategoryEditor @"Editor"
#define kAnalyticsActionEdit @"Edit"
#define kAnalyticsLabelEditFromFeed @"Edit from Feed"
#define kAnalyticsLabelEditFromGallery @"Edit from Gallery"


#define kAnalyticsCategoryOnboarding @"Onboarding"
#define kAnalyticsActionAcceptEula @"Accept Eula"
#define kAnalyticsActionDeclineEula @"Decline Eula"
#define kAnalyticsActionEmailEula @"Email Eula"
#define kAnalyticsActionConnectingAccount @"Connecting Account"
#define kAnalyticsActionConnectedAccount @"Connected Account"

#endif
