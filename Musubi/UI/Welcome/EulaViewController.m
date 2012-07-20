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
//  EULAViewController.m
//  musubi
//
//  Created by Ben Dodson on 7/20/12.
//  Copyright (c) 2012 Stanford University. All rights reserved.
//

#import "EULAViewController.h"

@interface EulaViewController ()

@end

@implementation EulaViewController
@synthesize eulaText = _eulaText, declineButton = _declineButton, acceptButton = _acceptButton, bottomBar = _bottomBar;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)doDecline:(id)sender {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"You must accept the EULA to use this app." message:@"You must accept the EULA to use Musubi. If you do not agree to the terms, click the Home button to exit." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles: nil];
    [alert show];
}

- (IBAction)doAccept:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber* version = [[NSNumber alloc] initWithInt:kEulaRequiredVersion];
    [defaults setObject:version forKey:kMusubiSettingsEulaAccepted];
    [[self navigationController] popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [_declineButton setAction:@selector(doDecline:)];
    [_acceptButton setAction:@selector(doAccept:)];
    [self loadEula];
}

- (void) loadEula {
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"eula" ofType:@"txt"];
    NSString* eulaText = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];

    filePath = [[NSBundle mainBundle] pathForResource:@"privacypolicy" ofType:@"txt"];
    NSString* privacyText = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];

    NSString* combined = [[eulaText stringByAppendingString:@"\n\n\n"] stringByAppendingString:privacyText];
    [_eulaText setText:combined];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (UINavigationItem *)navigationItem {
    UINavigationItem* item = [super navigationItem];
    item.hidesBackButton = YES;
    return item;
}

@end
