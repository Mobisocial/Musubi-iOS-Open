//
//  ViewController.m
//  musubi
//
//  Created by Willem Bult on 10/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "GroupListViewController.h"
#import "Download.h"
#import "GPSNearbyGroups.h"
#import "GroupProvider.h"

@implementation GroupListViewController
@synthesize groups;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self setGroups: [[Musubi sharedInstance] groups]];

    NSLog(@"Groups: %@", groups);
}

- (UINavigationItem *)navigationItem {
    return [[[UINavigationItem alloc] initWithTitle:@"Groups"] autorelease];
}

- (UITabBarItem *)tabBarItem {
    return [[[UITabBarItem alloc] initWithTitle:@"Groups" image:nil tag:0] autorelease];
}
/*
- (void) appManager:(NSObject *)mgr installedApp:(NSString *)name {
    [self loadResource: @"index.html" inApp: name];
}

- (void) loadResource: (NSString*) resource inApp: (NSString*) app {
    @try {
        NSURL* url = [self urlForResource: resource inApp:app];
		NSURLRequest *appReq = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:20.0];
		[self.webView loadRequest:appReq];
    } @catch (NSException* e) {
        NSString* html = [NSString stringWithFormat:@"<html><body> %@ </body></html>", [e description]];
		[self.webView loadHTMLString:html baseURL:nil];
    }
}

- (NSString*) pathForResource: (NSString*) resource inApp: (NSString*) app {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFolder = [documentsDirectory stringByAppendingPathComponent:app];
    
    NSError* error = nil;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:appFolder]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:appFolder withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    NSString* resourcePath = [appFolder stringByAppendingPathComponent:resource];
    return resourcePath;
}

- (NSURL*) urlForResource: (NSString*) resource inApp: (NSString*) app {
    NSURL *appURL = [NSURL URLWithString:resource];

	if([appURL scheme])
    {
        return appURL;
    } else {
		NSString* path = [self pathForResource:resource inApp:app];
		if (path == nil)
		{
            [[[NSException alloc] initWithName:@"RESOURCE_NOT_FOUND" reason:[NSString stringWithFormat:@"Resource '%@/%@' was not found.", app, resource] userInfo:nil] raise];
		}
		else {
			return [NSURL fileURLWithPath:path];
		}
	}
    
    return nil;
}*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return [groups count];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    Group* group = [groups objectAtIndex: indexPath.row];
    
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    cell.textLabel.text = [group name];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Group* group = [groups objectAtIndex: indexPath.row];
    NSLog(@"Group: %@", group);
    
    FeedViewController* feedViewController = (FeedViewController*) [[self storyboard] instantiateViewControllerWithIdentifier:@"feed"];
    [feedViewController setGroup: group];
    
    [[self navigationController] pushViewController:feedViewController animated:YES];
}

@end
