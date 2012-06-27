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


#import "FeedPhotoSource.h"
#import "FeedPhoto.h"
#import "ObjManager.h"
#import "Musubi.h"

@implementation FeedPhotoSource
@synthesize title = _title;
@synthesize photos = _photos;

/*
 Use this code to launch Sketch on top of a photo:
 
 NSString* appId = @"musubi.sketch";
 AppManager* appMgr = [[AppManager alloc] initWithStore: [Musubi sharedInstance].mainStore];
 MApp* app = [appMgr ensureAppWithAppId:appId];
 MObj* obj = // get the FeedPhoto's obj
 [(FeedViewController*)self.controller launchApp:app withObj:obj];
 
 */

- (id) initWithFeed:(MFeed*)feed {
    if ((self = [super init])) {
        // unlimited content size, we've already downloaded it once!
        [[TTURLRequestQueue mainQueue] setMaxContentLength:0];

        self.title = @"Conversation Photos";
        ObjManager* objManager = [[ObjManager alloc] initWithStore: [Musubi sharedInstance].mainStore];
        NSLog(@"Loading photos for %@...", feed);
        self.photos = [objManager pictureObjsInFeed:feed];
        NSLog(@"Loaded %d photos", self.photos.count);
    }
    return self;
}

#pragma mark TTModel

- (BOOL)isLoading {
    return FALSE;
}

- (BOOL)isLoaded {
    return TRUE;
}

#pragma mark TTPhotoSource

- (NSInteger)numberOfPhotos {
    return _photos.count;
}

- (NSInteger)maxPhotoIndex {
    return _photos.count-1;
}

- (id<TTPhoto>)photoAtIndex:(NSInteger)photoIndex {
    if (photoIndex < _photos.count) {
        return [[FeedPhoto alloc] initWithObj:[_photos objectAtIndex:photoIndex] andSource:self andIndex:photoIndex];
    } else {
        return nil;
    }
}
@end