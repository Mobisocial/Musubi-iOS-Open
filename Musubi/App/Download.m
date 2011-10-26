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
//  ResourceManager.m
//  musubi
//
//  Created by Willem Bult on 10/5/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Download.h"

@implementation Download

@synthesize fileData, path, delegate;

- (id)initWithPath: (NSString*) p andDelegate: (id<ResourceDownloadDelegate>) d {
    self = [super init];
    if (self) {
        
        [self setPath: p];
        [self setDelegate: d];
        
        started = NO;
    }
    
    return self;
}

- (void) startWithURL:(NSURL *)url {
    if (!started) {
        started = YES;
        
        fileData = [NSMutableData data];
        
        NSURLRequest *req = [NSURLRequest requestWithURL: url];
        [NSURLConnection connectionWithRequest:req delegate:self];                
    } else {
        [[[NSException alloc] initWithName:@"ALREADY_STARTED" reason:@"ResourceDownload already started" userInfo:nil] raise];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [fileData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [fileData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if ([fileData writeToFile:path atomically:NO] == YES) {
        [delegate resourceSavedToPath:path];
    } else {
        NSLog(@"writeToFile error");
    }
}

@end