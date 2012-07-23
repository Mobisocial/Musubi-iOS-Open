//
//  Obj.h
//  musubi
//
//  Created by Willem Bult on 10/13/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MObj;

@interface Obj : NSObject {
    NSString* _type;
    NSDictionary* _data;
    NSData* _raw;
}

@property (nonatomic) NSString* type;
@property (nonatomic) NSDictionary* data;
@property (nonatomic) NSData* raw;

- (id) initWithType: (NSString*) t;
- (id) initWithType: (NSString*) t data: (NSDictionary*) data andRaw: (NSData*) raw;
- (BOOL)processObjWithRecord: (MObj*) obj;

@end

@protocol RenderableObj

@end
