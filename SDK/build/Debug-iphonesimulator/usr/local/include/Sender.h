//
//  Sender.h
//  Musubi
//
//  Created by Willem Bult on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Sender : NSObject {
    NSData* i; // the serialized hashed identity of the sender who signed this message, including the type, hashed principal, and time period
    NSData* d; // the device identifier
}

@property (nonatomic) NSData* i;
@property (nonatomic) NSData* d;


@end
