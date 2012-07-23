//
//  ObjEncoder.h
//  Musubi
//
//  Created by Willem Bult on 3/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PreparedObj, MObj, MFeed, MApp, MDevice, MIdentity;

@interface ObjEncoder : NSObject

+ (PreparedObj*) prepareObj: (MObj*)obj forFeed: (MFeed*) feed andApp: (MApp*) app;
+ (NSData*) encodeObj: (PreparedObj*) obj;
+ (PreparedObj*) decodeObj: (NSData*) data;
+ (NSData*) computeUniversalHashFor: (NSData*) hash from: (MIdentity*) from onDevice: (MDevice*) device;

@end
