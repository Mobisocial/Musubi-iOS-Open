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
//  VerifyViewController.m
//  musubi
//
//  Created by Willem Bult on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VerifyViewController.h"
#import "WelcomeViewController.h"


@implementation VerifyViewController

@synthesize emailAuth = _emailAuth;
@synthesize verifySpinner = _verifySpinner;


/*
 + (VerifyViewController*) ensureView {
 UINavigationController* navController = (UINavigationController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
 
 VerifyViewController* verifyVC = nil;
 if ([navController.topViewController isKindOfClass:VerifyViewController.class]) {
 verifyVC = (VerifyViewController*)navController.topViewController;
 } else {
 verifyVC = [[UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"VerifyEmail"];
 [navController pushViewController:verifyVC animated:NO];
 }
 
 return verifyVC;
 }
 
 + (void) dismissView {
 UINavigationController* navController = (UINavigationController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
 
 if ([navController.topViewController isKindOfClass:VerifyViewController.class]) {
 [navController popViewControllerAnimated:YES];
 }
 }*/

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [self setVerifySpinner:nil];
    [super viewDidUnload];

    // Release any retained subviews of the main view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.verifySpinner startAnimating];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.verifySpinner stopAnimating];
    
    UINavigationController* navController = (UINavigationController*)[[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    if ([navController.topViewController isKindOfClass:WelcomeViewController.class]) {
        [navController popViewControllerAnimated:NO];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark AccountAuthManager delegate

- (void)accountWithType:(NSString *)type isConnected:(BOOL)connected {
//    [EmailAuthManager dismissView];
}

@end
