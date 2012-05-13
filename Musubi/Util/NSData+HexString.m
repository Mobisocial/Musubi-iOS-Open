
//
//  NSData+HexString.m
//  musubi
//
//  Created by MokaFive User on 5/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSData+HexString.h"

@implementation NSData (HexString)
-(NSString *)hexString 
{
    const unsigned char *dbytes = [self bytes];
    NSMutableString *hexStr =
    [NSMutableString stringWithCapacity:[self length]*2];
    int i;
    for (i = 0; i < [self length]; i++) {
        [hexStr appendFormat:@"%02x", dbytes[i]];
    }
    return [NSString stringWithString: hexStr];
}
@end
