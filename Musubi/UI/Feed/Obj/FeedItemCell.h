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


#import "Three20/Three20.h"

@class FeedItem, LikeView;

@interface FeedItemCell : TTTableLinkedItemCell {
    UILabel*      _senderLabel;
    UILabel*      _timestampLabel;
    UIImageView*  _profilePictureView;
    LikeView*     _likeView;
    
    UIButton*     _likeButton;
}

@property (nonatomic, readonly, retain) UILabel*      senderLabel;
@property (nonatomic, readonly, retain) UILabel*      timestampLabel;
@property (nonatomic, readonly, retain) UIImageView*  profilePictureView;
@property (nonatomic, readonly, retain) LikeView*     likeView;
@property (nonatomic, readonly, retain) UIButton*  likeButton;

+ (CGFloat) renderHeightForItem: (FeedItem*) item;

@end

@interface LikeView : UIView {
    UILabel* _label;
    UIImageView* _icon;
}

@property (nonatomic, readonly, retain) UILabel*      label;
@property (nonatomic, readonly, retain) UIImageView*      icon;

- (void)prepareForReuse;
- (void)setObject: (FeedItem*) item;
+ (CGFloat)renderHeightForItem:(FeedItem *)item;

@end