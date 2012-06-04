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
//  RecorderViewController.m
//  AudioTest
//
//  Created by Christophe Chong on 5/15/12.
//  Copyright (c) 2012 Stanford University. All rights reserved.
//

#import "AudioRecorderViewController.h"
#import <Foundation/Foundation.h>

@interface AudioRecorderViewController ()

@end

@implementation AudioRecorderViewController

@synthesize userIsRecording, filePath, activityView, recordButton, playButton, recorder, player, submitButton, delegate, backgroundView, audioDuration, audioDurationTextView;

/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/
 
+ (CGRect)makeCGRectWithCenter:(CGPoint)center width:(float)width height:(float)height 
{
    return CGRectMake(center.x-width/2, center.y-height/2, width, height);
}

#pragma mark - Preparation
- (void)loadView 
{
#define AVRECORDER_VIEW_FRAME_HEIGHT 420
#define AVRECORDER_VIEW_FRAME_WIDTH 320
#define AVRECORDER_TABBAR_HEIGHT 50
    self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, AVRECORDER_VIEW_FRAME_WIDTH, AVRECORDER_VIEW_FRAME_HEIGHT)];
    self.view.opaque = NO;
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    self.view.layer.opaque = NO;
    
    // TOOL BAR TO MOUNT BUTTONS ON
    UIImageView *toolBarView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"gradienttoolbar.png"]];
    [toolBarView setFrame:CGRectMake(0, self.view.frame.size.height-AVRECORDER_TABBAR_HEIGHT, AVRECORDER_VIEW_FRAME_WIDTH, AVRECORDER_TABBAR_HEIGHT)];
    toolBarView.userInteractionEnabled = YES;
    
    
    // RECORD BUTTON  
    self.recordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//    self.recordButton.frame = [[self class] makeCGRectWithCenter:CGPointMake(self.view.frame.size.width/2, 200) width:150 height:50];
    self.recordButton.bounds = CGRectMake(0, 0, 50, 30);
    [self.recordButton setCenter:CGPointMake(AVRECORDER_VIEW_FRAME_WIDTH/2, AVRECORDER_TABBAR_HEIGHT/2)];
    [self.recordButton setTitle:@"Record" forState:UIControlStateNormal];
    [self.recordButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:10]];
    [self.recordButton addTarget:self action:@selector(recordPressed) forControlEvents:UIControlEventTouchUpInside];
    
    // PLAY BUTTON -- Not supported in the real version
    /*
    self.playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.playButton.frame = [[self class] makeCGRectWithCenter:CGPointMake(self.view.frame.size.width/2, 200) width:150 height:50];
    [self.playButton setTitle:@"Play" forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(playPressed) forControlEvents:UIControlEventTouchUpInside];
    */
    
    // CANCEL (RETURN) BUTTON
    UIButton *returnButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    returnButton.bounds = CGRectMake(0, 0, 50, 30);
    [returnButton setCenter:CGPointMake(30, AVRECORDER_TABBAR_HEIGHT/2)];
    [returnButton setTitle:@"Record" forState:UIControlStateNormal];
    [returnButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:10]];
    [returnButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [returnButton addTarget:self action:@selector(dismissPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    // SUBMIT BUTTON
    self.submitButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.submitButton.bounds = CGRectMake(0, 0, 50, 30);
    [self.submitButton setCenter:CGPointMake(AVRECORDER_VIEW_FRAME_WIDTH - 30, AVRECORDER_TABBAR_HEIGHT/2)];
    [self.submitButton.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:10]];
    [self.submitButton setTitle:@"Submit" forState:UIControlStateNormal];

    [self.submitButton addTarget:self action:@selector(submitPressed) forControlEvents:UIControlEventTouchUpInside];
    self.submitButton.hidden = YES;
    self.submitButton.enabled = NO;
    
    // ACTIVITY
    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self.activityView setCenter:CGPointMake(AVRECORDER_VIEW_FRAME_WIDTH - 30, AVRECORDER_TABBAR_HEIGHT/2)];

    // AUDIO DURATION
    self.audioDurationTextView = [[UITextView alloc] init];
    [self.audioDurationTextView setBackgroundColor:[UIColor colorWithHue:0 saturation:0 brightness:0 alpha:0]];
    [self.audioDurationTextView setTextColor:[UIColor whiteColor]];
    [self.audioDurationTextView setFont:[UIFont fontWithName:@"Helvetica" size:60]];
    [self.audioDurationTextView setTextAlignment:UITextAlignmentCenter];
    [self.audioDurationTextView setFrame:CGRectMake(0, 0, 200, 75)];
    [self.audioDurationTextView setCenter:CGPointMake(AVRECORDER_VIEW_FRAME_WIDTH/2, AVRECORDER_VIEW_FRAME_HEIGHT/2-20)];
    [self.audioDurationTextView setText:[NSString stringWithFormat:@"00:%i", (ARVC_MAX_AUDIO_DURATION)]];
    
    [self.view addSubview:self.audioDurationTextView];
    [self.view addSubview:toolBarView];
    [toolBarView addSubview:self.submitButton];
    [toolBarView addSubview:self.recordButton];
//    [self.view addSubview:self.playButton];
    [toolBarView addSubview:returnButton];
    [toolBarView addSubview:self.activityView];
    
}


/*
 * Automatically sets the time remaining based on the difference between current duration and max audio duration
 */
- (void)updateAudioDurationTextField
{
    int remainingSeconds = ARVC_MAX_AUDIO_DURATION - self.audioDuration;
    if (remainingSeconds < 0) {
        remainingSeconds = 0;
    }
    NSString *remainingSecondsString = [NSString stringWithFormat:@"%i", remainingSeconds];
    if (remainingSecondsString.length == 1) {
        remainingSecondsString = [@"0" stringByAppendingString:remainingSecondsString];
    }
    [self.audioDurationTextView setText:[@"00:" stringByAppendingString:remainingSecondsString]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    NSLog(@"View did load");
    self.filePath = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"temp.caf"]];

    
    // Setup AudioSession
    AVAudioSession *avSession = [AVAudioSession sharedInstance];
    [avSession setCategory:AVAudioSessionCategoryPlayAndRecord error:NULL];
  	[avSession setActive:YES error: NULL];
//    self.playButton.hidden = YES;
    
}

#pragma mark - Timer
- (void)checkRecordingTime
{
    if ([self.recorder isRecording]) {
        self.audioDuration++;
        [self updateAudioDurationTextField];
        if (self.audioDuration >= ARVC_MAX_AUDIO_DURATION) {
            [self stopPressed];
        }
        else {
            [NSTimer scheduledTimerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(checkRecordingTime)
                                           userInfo:nil
                                            repeats:NO];
        }
    }
}


#pragma mark - Button Actions

- (void)dismissPressed:(id)sender
{
    [self stopPressed];
//    [self dismissModalViewControllerAnimated:YES];
    [self.view removeFromSuperview];
}

- (void)stopPressed {
    if ([self.recorder isRecording] == NO) {
        return;
    }
    [self.recordButton setTitle:@"Record" forState:UIControlStateNormal];
    self.userIsRecording = NO;
//    self.playButton.hidden = NO;
//    self.playButton.enabled = YES;
    self.submitButton.hidden = NO;
    self.submitButton.enabled = YES;
    
    [self.activityView stopAnimating];
    
    [self.recorder stop];
}

- (void)recordPressed
{
    if (self.userIsRecording) {
        [self stopPressed];
    }
    else {
        self.userIsRecording = YES;
//        self.playButton.enabled = NO;
//        self.playButton.hidden = YES;
        self.submitButton.enabled = NO;
        self.submitButton.hidden = YES;
        [self.recordButton setTitle:@"Stop" forState:UIControlStateNormal];
        [self.activityView startAnimating];
        
		NSMutableDictionary* recordSetting = [[NSMutableDictionary alloc] init];
        [recordSetting setValue:[NSNumber numberWithInt:8000] forKey:AVSampleRateKey];
        [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
		[recordSetting setValue:[NSNumber numberWithInt: 16] forKey:AVLinearPCMBitDepthKey]; 
        [recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey]; 
        [recordSetting setValue:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
        
        // Remove old file
        NSFileManager *filemanager = [NSFileManager defaultManager];
        if ([filemanager fileExistsAtPath:[self.filePath absoluteString]]) {
            [filemanager removeItemAtURL:self.filePath error:NULL];
        }

        // Record
        NSError *error = [NSError alloc];

        self.recorder = [[AVAudioRecorder alloc] initWithURL:self.filePath settings:recordSetting error:&error];

		[recorder setDelegate:self];
		[recorder prepareToRecord];
		[recorder record];
        // Begin timing -- Begin at 1
        self.audioDuration = 1;
        [self updateAudioDurationTextField];
        [NSTimer scheduledTimerWithTimeInterval:1.0
                                         target:self
                                       selector:@selector(checkRecordingTime)
                                       userInfo:nil
                                        repeats:NO];
    }
}

- (void)playPressed
{

    self.player = [[AVAudioPlayer alloc]initWithContentsOfURL:self.filePath error:nil];

    [self.player setDelegate:self];
    [self.player prepareToPlay];
    [self.player play];
}

- (void)submitPressed
{
//    NSFileManager *filemanager = [NSFileManager defaultManager];
//    NSError *error = [NSError alloc];
//    NSDictionary *fileAttributes = [filemanager attributesOfItemAtPath:[self.filePath absoluteString] error:&error];
//    if (error) {
//        NSLog(@"Error: %@", [error description]);
//    }
//    NSLog(@"%@", [fileAttributes objectForKey:NSFileSize]);    
    [self.delegate userChoseAudioData:self.filePath withDuration:self.audioDuration];
}

#pragma mark - Lifecycle


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    NSLog(@"View did unload");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
