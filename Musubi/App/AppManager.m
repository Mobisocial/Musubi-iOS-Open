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
//  AppManager.m
//  musubi
//
//  Created by Willem Bult on 10/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppManager.h"
#import "ZipArchive.h"

@implementation AppManager

@synthesize delegate;

- (id) initWithDelegate: (id<AppManagerDelegate>) d {
    self = [super init];
    if (self) {
        [self setDelegate:d];
    }
    
    return self;
}

- (void) downloadAppFromURL: (NSURL*) url {
    NSString* name = [NSString stringWithFormat:@"__TMP__%@", [url lastPathComponent]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appPath = [documentsDirectory stringByAppendingPathComponent:name];
    
    Download* download = [[[Download alloc] initWithPath:appPath andDelegate:self] autorelease];
    [download startWithURL:url];
}

- (void)resourceSavedToPath:(NSString *)path {
    NSString* targetPath = [path stringByReplacingOccurrencesOfString:@"__TMP__" withString:@""];
    
    ZipArchive* archive = [[[ZipArchive alloc] init] autorelease];
    [archive UnzipOpenFile: path];
    [archive UnzipFileTo:targetPath overWrite:YES];
    
    [delegate appManager:self installedApp: [targetPath lastPathComponent]];
}

@end
