//
//  URLCommand.h
//  musubi
//
//  Created by Willem Bult on 11/18/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Musubi.h"
#import "XQueryComponents.h"
#import "App.h"

@interface URLFeedCommand : NSObject {
    NSURL* url;
    NSString* className;
    NSString* methodName;
    NSDictionary* parameters;

    App* app;
}

@property (nonatomic,retain) NSURL* url;
@property (nonatomic,retain) NSString* className;
@property (nonatomic,retain) NSString* methodName;
@property (nonatomic,retain) NSDictionary* parameters;
@property (nonatomic,retain) App* app;

- (NSString*) execute;
+ (id)createFromURL:(NSURL *)url withApp:(App*) app;

@end


@interface FeedCommand  : URLFeedCommand
- (id) messagesWithParams: (NSDictionary*) params;
- (id) postWithParams: (NSDictionary*) params;

@end
