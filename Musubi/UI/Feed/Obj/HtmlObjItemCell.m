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
//  HtmlObjItemCell.m
//  musubi
//
//  Created by Ben Dodson on 5/27/12.
//  Copyright (c) 2012 Stanford University. All rights reserved.
//

#import "HtmlObjItemCell.h"
#import "HtmlObjItem.h"

@implementation HtmlObjItemCell {
    UIWebView* webView;
}

@synthesize webView;

- (UIWebView*) webView {
    if (!webView) {
        webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 80, 300)];
        [webView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [webView setContentMode:UIViewContentModeScaleAspectFit];
        [self.contentView addSubview:webView];   
    }
    return webView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.webView.frame = CGRectMake(self.detailTextLabel.frame.origin.x, self.detailTextLabel.frame.origin.y + 5, self.detailTextLabel.frame.size.width, self.detailTextLabel.frame.size.height);
}


- (void)setObject:(id)object {
    [super setObject:object];
    
    //self.detailTextLabel.text = ((HtmlObjItem*) object).html;
    [self.webView loadHTMLString:((HtmlObjItem*) object).html baseURL:[NSURL URLWithString:@"http://localhost"]];
}

+ (CGFloat)renderHeightForItem:(FeedItem *)item {
    return 180;
}


@end
