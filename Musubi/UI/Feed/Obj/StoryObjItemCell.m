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
//  StoryObjItemCell.m
//  musubi
//
//  Created by Ben Dodson on 5/31/12.
//  Copyright (c) 2012 Stanford University. All rights reserved.
//

#import "StoryObjItemCell.h"
#import "StoryObj.h"

@implementation StoryObjItemCell

+ textForItem:(ManagedObjFeedItem*) item {
    NSString* text = [item.parsedJson objectForKey:kObjFieldStoryText];
    NSString* title = [item.parsedJson objectForKey:kObjFieldStoryTitle];
    NSString* url = [item.parsedJson objectForKey:kObjFieldStoryUrl];
    return [NSString stringWithFormat:@"[%@]\n\n%@\n\n%@", title, text, url];
}

+ (CGFloat)renderHeightForItem:(ManagedObjFeedItem *)item {
    NSString* text = [StoryObjItemCell textForItem:item];
    CGSize size = [text sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(244, 1024) lineBreakMode:UILineBreakModeWordWrap];
    return size.height;
}

- (void)setObject:(id)object {
    [super setObject:object];
    self.detailTextLabel.text = [StoryObjItemCell textForItem:object];
    
    //UILabel* link = [[UILabel alloc] initWithFrame:self.detailTextLabel.frame];
    //link.text = [item.parsedJson objectForKey:kObjFieldStoryUrl];
    //[self.contentView addSubview:link];
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

@end
