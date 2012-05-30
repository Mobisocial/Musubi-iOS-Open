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
//  StatusObjItemCell.m
//  musubi
//
//  Created by Willem Bult on 4/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "StatusObjItemCell.h"
#import "ManagedObjItem.h"
#import "ObjHelper.h"

@implementation StatusObjItemCell

+ (NSString*) textForItem: (ManagedObjItem*) item {
    NSString* text = nil;
    text = [[item parsedJson] objectForKey: kObjFieldText];
    if (text == nil) {
        text = [[item parsedJson] objectForKey: kObjFieldStatusText];
    }
    return text;
}

+ (CGFloat)renderHeightForItem:(FeedItem *)item {
    CGSize size = [[StatusObjItemCell textForItem: (ManagedObjItem*)item] sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(244, 1024) lineBreakMode:UILineBreakModeWordWrap];
    return size.height;
}

- (void)setObject:(id)object {
    [super setObject:object];
    NSString* text = [StatusObjItemCell textForItem:(ManagedObjItem*)object];
    self.detailTextLabel.text = text;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

@end
