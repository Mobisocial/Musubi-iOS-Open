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
//  VoiceObjItemCell.m
//  musubi
//
//  Created by Ben Dodson on 5/31/12.
//  Copyright (c) 2012 Stanford University. All rights reserved.
//

#import "VoiceObjItemCell.h"
#import "Three20UI/UIViewAdditions.h"
#import <AVFoundation/AVPlayer.h>

@implementation VoiceObjItemCell

+ (CGFloat)renderHeightForItem:(FeedItem *)item {
    return 50;
}

- (void) playButtonPressed: (UIView*) source {
    TTTableViewCell* cell = (TTTableViewCell*)source.superview.superview;
    ManagedObjFeedItem* item = cell.object;
    // TODO: play the item's content
}

- (UIButton*)playButton {
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:[UIImage imageNamed:@"Play_icon_status.png"] forState:UIControlStateNormal];
        _playButton.userInteractionEnabled = YES;
        [_playButton addTarget:self action:@selector(playButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

        [self.contentView addSubview:_playButton];
    }
    return _playButton;
}

- (void)setObject:(id)object {
    [super setObject:object];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.playButton sizeToFit];
    _playButton.width = 50;
    _playButton.height = 50;
    self.playButton.frame = CGRectMake(self.detailTextLabel.frame.origin.x + 20, self.detailTextLabel.frame.origin.y + 5, self.playButton.frame.size.width, self.playButton.frame.size.height);
}
@end
