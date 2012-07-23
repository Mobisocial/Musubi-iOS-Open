//
//  Recipient.h
//  Musubi
//
//  Created by Willem Bult on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Recipient : NSObject {
    NSData* i; // the serialized hashed identity, including the type, hashed principal, and time period
    NSData* k; // the IBE encrypted key block
    NSData* s; // the IBE signature block, signature for the key block||device, the identity is in the sender block of the message
    NSData* d; // the encrypted block of secrets for the message for this person
}

@property (nonatomic) NSData* i;
@property (nonatomic) NSData* k;
@property (nonatomic) NSData* s;
@property (nonatomic) NSData* d;

@end
