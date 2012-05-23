
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

@implementation NSString (HexString)

- (NSData*) dataFromHex
{
    NSMutableData *data = [[NSMutableData alloc] init];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i;
    for (i=0; i < 8; i++) {
        byte_chars[0] = [self characterAtIndex:i*2];
        byte_chars[1] = [self characterAtIndex:i*2+1];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1]; 
    }
    return data;
}
@end
