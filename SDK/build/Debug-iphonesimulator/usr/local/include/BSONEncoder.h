//
//  BSONEncoder.h
//  Musubi
//
//  Created by Willem Bult on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Message, Secret, PreparedObj;

@interface BSONEncoder : NSObject

+ (NSData*) encodeMessage: (Message*) m;
+ (NSData*) encodeSecret: (Secret*) s;
+ (NSData*) encodeObj: (PreparedObj*) o;

+ (Message*) decodeMessage: (NSData*) data;
+ (Secret*) decodeSecret: (NSData*) data;
+ (PreparedObj*) decodeObj: (NSData*) data;
@end
