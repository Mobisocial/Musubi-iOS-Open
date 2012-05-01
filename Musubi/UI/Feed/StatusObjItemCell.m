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
#import "StatusObj.h"

@implementation StatusObjItemCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setObject:(id)object {
    [super setObject: object];
    return;
//    self.textLabel.textColor = TTSTYLEVAR(myHeadingColor);  
//    self.textLabel.font = TTSTYLEVAR(myHeadingFont);  
//    self.textLabel.textAlignment = UITextAlignmentRight;  
//    self.textLabel.contentMode = UIViewContentModeCenter;  
    self.textLabel.lineBreakMode = UILineBreakModeWordWrap;  
    self.textLabel.numberOfLines = 0;  
    self.textLabel.text = [((StatusObj*) object) text];
    
//    self.detailTextLabel.textColor = TTSTYLEVAR(mySubtextColor);  
//    self.detailTextLabel.font = TTSTYLEVAR(mySubtextFont);  
//    self.detailTextLabel.textAlignment = UITextAlignmentLeft;  
    self.detailTextLabel.contentMode = UIViewContentModeTop;  
    self.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;  
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
