//
//  EncodedMessageManager.h
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EntityManager.h"

@class MEncodedMessage;

@interface EncodedMessageManager : EntityManager 

- (id) initWithStore: (PersistentModelStore*) s;
- (NSArray*) unsentOutboundMessages;
@end
