
//
//  XQueryComponents.m
//  musubi
//
//  Created by Willem Bult on 10/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "XQueryComponents.h"

@implementation NSString (XQueryComponents)
- (NSString *)stringByDecodingURLFormat
{
    NSString *result = [self stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    result = [result stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

- (NSString *)stringByEncodingURLFormat
{
    return [(NSString *)CFURLCreateStringByAddingPercentEscapes(
                                                               NULL,
                                                               (CFStringRef)self,
                                                               NULL,
                                                               (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                               kCFStringEncodingUTF8 ) autorelease];
}

- (NSMutableDictionary *)dictionaryFromQueryComponents
{
    NSMutableDictionary *queryComponents = [[[NSMutableDictionary alloc] init] autorelease];
    for(NSString *keyValuePairString in [self componentsSeparatedByString:@"&"])
    {
        NSArray *keyValuePairArray = [keyValuePairString componentsSeparatedByString:@"="];
        if ([keyValuePairArray count] < 2) continue; // Verify that there is at least one key, and at least one value.  Ignore extra = signs
        NSString *key = [[keyValuePairArray objectAtIndex:0] stringByDecodingURLFormat];
        NSString *value = [[keyValuePairArray objectAtIndex:1] stringByDecodingURLFormat];
        [queryComponents setObject:value forKey:key];
        /*
        NSMutableArray *results = [queryComponents objectForKey:key]; // URL spec says that multiple values are allowed per key
        if(!results) // First object
        {
            results = [NSMutableArray arrayWithCapacity:1];
            [queryComponents setObject:results forKey:key];
        }
        [results addObject:value];*/
    }
    return queryComponents;
}
@end

@implementation NSURL (XQueryComponents)
- (NSMutableDictionary *)queryComponents
{
    return [[self query] dictionaryFromQueryComponents];
}
@end

@implementation NSDictionary (XQueryComponents)
- (NSString *)stringFromQueryComponents
{
    NSString *result = nil;
    for(NSString *key in [self allKeys])
    {
        key = [key stringByEncodingURLFormat];
        NSArray *allValues = [self objectForKey:key];
        if([allValues isKindOfClass:[NSArray class]])
            for(NSString *value in allValues)
            {
                value = [[value description] stringByEncodingURLFormat];
                if(!result)
                    result = [NSString stringWithFormat:@"%@=%@",key,value];
                else 
                    result = [result stringByAppendingFormat:@"&%@=%@",key,value];
            }
        else {
            NSString *value = [[allValues description] stringByEncodingURLFormat];
            if(!result)
                result = [NSString stringWithFormat:@"%@=%@",key,value];
            else 
                result = [result stringByAppendingFormat:@"&%@=%@",key,value];
        }
    }
    return result;
}
@end