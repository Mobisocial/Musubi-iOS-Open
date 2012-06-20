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
//  MusubiStyleSheet.m
//  musubi
//
//  Created by Willem Bult on 6/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MusubiStyleSheet.h"

@implementation MusubiStyleSheet

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark TTDefaultStyleSheet


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UIColor*)navigationBarTintColor {
    //return [UIColor colorWithRed:125.0/255.0 green:41.0/255.0 blue:165.0/255.0 alpha:1]; // Purple
    return [UIColor colorWithRed:5.0/255.0 green:115.0/255.0 blue:155.0/255.0 alpha:1]; // Cyan
//    return [UIColor colorWithRed:255.0/255.0 green:100.0/255.0 blue:0.0/255.0 alpha:1]; // Orange
//    return [UIColor colorWithRed:10.0/255.0 green:115.0/255.0 blue:255.0/255.0 alpha:1]; // Blue
}

- (UIColor *)tablePlainBackgroundColor {
    return [UIColor colorWithPatternImage:[UIImage imageNamed:@"background.jpg"]];
//    return [UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1];
}

- (UIColor *)tablePlainCellSeparatorColor {
    return [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1];
}

- (UIColor *)tableHeaderTintColor {
    return [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1];
}

- (UIColor *)tableHeaderTextColor {
//    return [UIColor colorWithRed:30.0/255.0 green:120.0/255.0 blue:200.0/255.0 alpha:1];
    return [UIColor colorWithRed:110.0/255.0 green:110.0/255.0 blue:110.0/255.0 alpha:1];
}

- (UITableViewCellSelectionStyle)tableSelectionStyle {
    return UITableViewCellSelectionStyleGray;
}

- (UIColor *)tableHeaderShadowColor {
    return [UIColor whiteColor];
}

- (UIColor *)linkTextColor {
    return [UIColor colorWithRed:10.0/255.0 green:115.0/255.0 blue:255.0/255.0 alpha:1];
}

@end
