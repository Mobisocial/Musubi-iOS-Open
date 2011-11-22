//
//  HTMLFeedViewController.m
//  musubi
//
//  Created by Willem Bult on 11/17/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "HTMLAppViewController.h"

@implementation HTMLAppViewController

@synthesize feed, app;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        updates = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSURL* html = [[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html" subdirectory:[NSString stringWithFormat: @"apps/%@", app.name]];
    [webView loadRequest:[NSURLRequest requestWithURL:html]];
    [webView setDelegate:self];
    
    [[Musubi sharedInstance] listenToGroup:feed withListener:self];
}

- (void)webViewDidFinishLoad:(UIWebView *)wv {
    // Launch app
    NSError* err = nil;
    SBJsonWriter* writer = [[SBJsonWriter alloc] init];
    NSString* feedJson = [writer stringWithObject: [feed json] error:&err];
    if (err != nil) {
        NSLog(@"Error: %@", err);
    }

    NSString* jsString = [NSString stringWithFormat:@"if (typeof Musubi !== 'undefined') {Musubi._launchApp(%@);} else {alert('Musubi library not loaded. Please include musubiLib.js');}", feedJson];
    /*
    NSString* jsString = [NSString stringWithFormat:@"function checkMusubi() {if (typeof Musubi !== 'undefined') {Musubi._launchApp(%@);} else {setTimeout(checkMusubi, 500);}}; checkMusubi() ", feedJson];*/
    [wv performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:jsString waitUntilDone:NO];    
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [updates release];
    updates = nil;
    
    [webView release];
    webView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// This allows us to execute functions from Javascript. We can open URL's in the format musubi://class.method?key=value
- (BOOL)webView:(UIWebView *)wv shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSURL* url = [request URL];
    
    if ([[url scheme] isEqualToString:@"musubi"]) {
        URLFeedCommand* cmd = [URLFeedCommand createFromURL:url withFeed:feed];
        id result = [cmd execute];
        
        SBJsonWriter* writer = [[SBJsonWriter alloc] init];
        NSError* err = nil;
        NSString* json = [writer stringWithObject: result error:&err];
        
        if (err != nil) {
            NSLog(@"JSON Encoding error: %@", err);
        }
        
        NSString* jsString = [NSString stringWithFormat:@"Musubi.platform._commandResult(%@);", json];
        [wv performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:jsString waitUntilDone:FALSE];
        return NO;
    } else {
        return YES;
    }
}

- (void)newMessage:(SignedMessage *)message {
    SBJsonWriter* writer = [[SBJsonWriter alloc] init];
    NSError* err = nil;
    NSString* jsString = [NSString stringWithFormat:@"Musubi._newMessage(%@);", [writer stringWithObject:[message json] error:&err]];
    if (err != nil) {
        NSLog(@"JSON Encoding error: %@", err);
    }
    [webView performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:jsString waitUntilDone:FALSE];
}

@end
