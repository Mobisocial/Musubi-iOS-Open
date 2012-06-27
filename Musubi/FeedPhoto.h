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


#import <Foundation/Foundation.h>
#import <Three20/Three20.h>
#import "MObj.h"
#import "MFeed.h"
#import "FeedPhotoSource.h"

@interface FeedPhoto : NSObject <TTPhoto> {
    NSString *_caption;
    NSString *_urlLarge;
    NSString *_urlSmall;
    NSString *_urlThumb;
    id <TTPhotoSource> _photoSource;
    CGSize _size;
    NSInteger _index;
}

@property (nonatomic, copy) NSString *caption;
@property (nonatomic, copy) NSString *urlLarge;
@property (nonatomic, copy) NSString *urlSmall;
@property (nonatomic, copy) NSString *urlThumb;
@property (nonatomic, strong) id <TTPhotoSource> photoSource;
@property (nonatomic) CGSize size;
@property (nonatomic) NSInteger index;

- (id)initWithObj: (MObj*)obj;
- (id)initWithObj:(MObj *)obj andSource:(FeedPhotoSource*)source andIndex: (NSInteger) index;

@end