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


#import "FeedPhoto.h"
#import "FeedPhotoSource.h"
#import "SBJsonParser.h"
#import "PictureObj.h"
#import "Musubi.h"

@implementation FeedPhoto
@synthesize caption = _caption;
@synthesize urlLarge = _urlLarge;
@synthesize urlSmall = _urlSmall;
@synthesize urlThumb = _urlThumb;
@synthesize photoSource = _photoSource;
@synthesize size = _size;
@synthesize index = _index;
@synthesize obj = _obj;

- (id)initWithObj: (MObj*) obj {
    if (self = [super init]) {
        FeedPhotoSource* source = [[FeedPhotoSource alloc] initWithFeed:obj.feed];
        NSInteger position = [source.photos indexOfObject:obj];
        self = [self initWithObj:obj andSource:source andIndex:position];
    }
    return self;
}

- (id)initWithObj: (MObj*) obj andSource: (FeedPhotoSource*)source andIndex: (NSInteger) index {
    if (self = [super init]) {
        _obj = obj;
        if (obj.json) {
            SBJsonParser* parser = [[SBJsonParser alloc] init];
            NSDictionary *json = [parser objectWithString:obj.json];
            self.caption = [json objectForKey:kTextField];
        }
        self.urlLarge = [Musubi urlForObjRaw:obj];
        self.urlSmall = self.urlLarge;
        self.urlThumb = self.urlLarge;
        self.index = index;
        UIImage* image = [[UIImage alloc] initWithData:obj.raw];
        self.size = [image size];
        self.photoSource = source;
    }
    return self;
}

#pragma mark TTPhoto

- (NSString*)URLForVersion:(TTPhotoVersion)version {
    switch (version) {
        case TTPhotoVersionLarge:
            return _urlLarge;
        case TTPhotoVersionMedium:
            return _urlLarge;
        case TTPhotoVersionSmall:
            return _urlSmall;
        case TTPhotoVersionThumbnail:
            return _urlThumb;
        default:
            return nil;
    }
}

@end