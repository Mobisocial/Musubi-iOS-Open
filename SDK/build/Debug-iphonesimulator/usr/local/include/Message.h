//
//  Message.h
//  Musubi
//
//  Created by Willem Bult on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Sender;

@interface Message : NSObject {
    uint32_t v; // version
    Sender* s; // information about the sender
    NSData* i; // the iv for the key blocks
    BOOL l; // the blind flag
    NSData* a; // the app id
    NSArray* r; // the key blocks
    NSData* d; // the encrypted data
}

@property (nonatomic, assign) uint32_t v;
@property (nonatomic) Sender* s;
@property (nonatomic) NSData* i;
@property (nonatomic, assign) BOOL l;
@property (nonatomic) NSData* a;
@property (nonatomic) NSArray* r;
@property (nonatomic) NSData* d;

@end
