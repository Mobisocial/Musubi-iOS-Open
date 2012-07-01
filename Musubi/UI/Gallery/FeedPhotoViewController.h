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
//  FeedPhotoViewController.h
//  musubi
//
//  Created by Willem Bult on 6/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Three20/Three20.h"

@class FeedViewController, FeedPhoto;


@interface FeedPhotoViewController : TTPhotoViewController<UIActionSheetDelegate> {
    //UIBarButtonItem* _actionButton;
    
}

@property (nonatomic, readonly) UIBarButtonItem* actionButton;
@property (nonatomic, retain) FeedViewController* feedViewController;


- (id) initWithFeedViewController: (FeedViewController*) feedVC andPhoto: (FeedPhoto*) photo;

@end
