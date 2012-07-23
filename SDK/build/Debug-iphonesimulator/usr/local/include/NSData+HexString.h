//
//  NSData+HexString.h
//  musubi
//
//  Created by MokaFive User on 5/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (HexString)
- (NSString*)hexString;
@end

@interface NSString (HexString)
- (NSData*) dataFromHex;
@end