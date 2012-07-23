//
//  JoinRequestObj.h
//  musubi
//
//  Created by T.J. Purtell on 6/17/12.
//  Copyright (c) 2012 Stanford MobiSocial Labratory. All rights reserved.
//

#import "Obj.h"
#define kObjTypeJoinRequest @"join_request"

@interface JoinRequestObj : Obj
- (id) initWithIdentities: (NSArray*) ids;
- (id) initWithData: (NSDictionary*) data;
@end
