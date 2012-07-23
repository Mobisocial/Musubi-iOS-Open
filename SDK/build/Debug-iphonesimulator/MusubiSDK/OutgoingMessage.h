//
//  OutgoingMessage.h
//  Musubi
//
//  Created by Willem Bult on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MIdentity;

@interface OutgoingMessage : NSObject {
    MIdentity* fromIdentity; // the reference to the identity that i send the message as
    NSArray* recipients; // a list of all of the recipients, some of which I may or may not really know, it probably includes me
    NSData* data; // the actual private message bytes that are decrypted
    NSData* hash; // the hash of data
    BOOL blind; // a flag that control whether client should see the full recipient list
    NSData* app; // the id of the application namespace
}

@property (nonatomic) MIdentity* fromIdentity;
@property (nonatomic) NSArray* recipients;
@property (nonatomic) NSData* data;
@property (nonatomic) NSData* hash;
@property (nonatomic, assign) BOOL blind;
@property (nonatomic) NSData* app;

@end
