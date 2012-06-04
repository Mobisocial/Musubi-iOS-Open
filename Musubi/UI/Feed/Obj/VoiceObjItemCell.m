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
#import <AudioToolbox/AudioToolbox.h>
#import "VoiceObj.h"

#define kVoiceObjText @"<Voice messages coming soon>"

@implementation VoiceObjItemCell

@synthesize playButton = _playButton, player, audioDuration, currentAudioDuration;

+ (void)prepareItem:(ManagedObjFeedItem *)item {
    item.computedData = item.managedObj.raw;
}

+ (CGFloat)renderHeightForItem:(FeedItem *)item {
//    CGSize size = [kVoiceObjText sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(244, 1024) lineBreakMode:UILineBreakModeWordWrap];
//    return size.height;
    return 50;
}

- (NSString*)formattedSecondStringWithSeconds:(int)seconds
{
    NSString *secondsString = [NSString stringWithFormat:@"%i", seconds];
    if (secondsString.length == 1) {
        secondsString = [@"0" stringByAppendingString:secondsString];
    }
    return secondsString;
}

- (void)updateCurrentAudioDurationTextField
{
    int remainingSeconds = self.currentAudioDuration;
    if (remainingSeconds < 0) {
        remainingSeconds = 0;
    }
    NSString *remainingSecondsString = [self formattedSecondStringWithSeconds:remainingSeconds];
    [self.playButton setTitle:[@"00:" stringByAppendingString:remainingSecondsString] forState:UIControlStateNormal];
}

- (void)resetCurrentAudioDurationTextField
{
    NSString *totalSecondsString = [self formattedSecondStringWithSeconds:self.audioDuration];
    [self.playButton setTitle:[@"Play Voice Note 00:" stringByAppendingString:totalSecondsString] forState:UIControlStateNormal];

}

#pragma mark - Timer
- (void)checkRecordingTime
{
    if ([self.player isPlaying]) {
        self.currentAudioDuration--;
        [self updateCurrentAudioDurationTextField];
        if (self.currentAudioDuration >= 0) {
            [NSTimer scheduledTimerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(checkRecordingTime)
                                           userInfo:nil
                                            repeats:NO];

        }
        else {
            [self resetCurrentAudioDurationTextField];
        }
    }
    else {
        [self resetCurrentAudioDurationTextField];    
    }
}

- (UIButton *)playButton
{
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [_playButton setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [self resetCurrentAudioDurationTextField];       
        [_playButton addTarget:self action:@selector(playPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:_playButton];
    }
    
    return _playButton;
}

- (void)playPressed
{
    if ([self.player isPlaying] == NO) {

        NSLog(@"Play button pressed!");
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
        AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    
        [self.player setVolume:0.5];
        [self.player play];
        self.currentAudioDuration = self.audioDuration;
        [self updateCurrentAudioDurationTextField];
        [NSTimer scheduledTimerWithTimeInterval:1.0
                                         target:self
                                       selector:@selector(checkRecordingTime)
                                       userInfo:nil
                                        repeats:NO];

    }
    else {
        [self.player stop];
        [self.player prepareToPlay];
    }
}

- (void)setObject:(ManagedObjFeedItem*)object {
    [super setObject:object];
    NSString* durationText = [object.parsedJson objectForKey:kObjFieldVoiceDuration];
    self.audioDuration = [durationText intValue];
    self.player = [[AVAudioPlayer alloc] initWithData:object.computedData error:NULL];
    self.player.delegate = self;
    [self.player prepareToPlay];
//    self.detailTextLabel.text = kVoiceObjText;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSLog(@"Done playing");
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.playButton.frame = CGRectMake(self.detailTextLabel.frame.origin.x, self.detailTextLabel.frame.origin.y + 5, self.detailTextLabel.frame.size.width, self.detailTextLabel.frame.size.height);
}
@end
