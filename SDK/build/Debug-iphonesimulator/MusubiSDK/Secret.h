//
//  Secret.h
//  Musubi
//
//  Created by Willem Bult on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Secret : NSObject {
    NSData* h; // the hash of the the decrypted data field
    uint64_t q; // the sequence number for the message
    NSData* k; // the actual aes key for the message body
}

@property (nonatomic) NSData* h;
@property (nonatomic, assign) uint64_t q;
@property (nonatomic) NSData* k;

@end
