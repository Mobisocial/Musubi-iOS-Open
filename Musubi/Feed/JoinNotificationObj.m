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
//  JoinNotificationObj.m
//  musubi
//
//  Created by Willem Bult on 10/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "JoinNotificationObj.h"
#import "SBJsonParser.h"
#import "SBJson.h"

@implementation JoinNotificationObj

@synthesize uri;

- (id)initWithURI:(NSString *)u {
    
    self = [super initWithType:kObjTypeJoinNotification];
    if (self != nil) {
        self.uri = u;
    }
    
    return self;
}

- (NSDictionary *)json {
    NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:2];
    [dict setObject:type forKey:@"type"];
    [dict setObject:uri forKey:@"uri"];
    
    return dict;
}


- (CGFloat)renderHeight {
    CGSize size = [@"I'm here" sizeWithFont:[UIFont systemFontOfSize:15] constrainedToSize:CGSizeMake(300, 1024) lineBreakMode:UILineBreakModeWordWrap];
    return size.height;
}

- (UIView *)render {
    UILabel* label = [[UILabel alloc] init];
    [label setFont: [UIFont systemFontOfSize:15]];
    [label setText: @"I'm here"];
    [label setLineBreakMode:UILineBreakModeWordWrap];
    
    CGSize size = CGSizeMake(300, [self renderHeight]);
    [label setFrame:CGRectMake(0, 0, size.width, size.height)];
    
    return label;
}
@end