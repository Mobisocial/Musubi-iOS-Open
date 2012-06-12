/*
 * Copyright 2012 The Stanford MobiSocial Laboratory
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


//
//  AMQPSender.h
//  Musubi
//
//  Created by Willem Bult on 3/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "AMQPThread.h"

@class MEncodedMessage;

@interface AMQPSender : NSObject

@property (nonatomic, strong) NSOperationQueue* queue;
@property (nonatomic, strong) NSMutableArray* pending;
@property (nonatomic, retain) AMQPConnectionManager* connMngr;
@property (nonatomic, strong) NSMutableSet* declaredGroups;
@property (nonatomic, strong) NSCondition* messagesWaitingCondition;
@property (nonatomic, retain) PersistentModelStoreFactory* storeFactory;
@property (nonatomic, assign) int groupProbeChannel;

- (id)initWithConnectionManager:(AMQPConnectionManager *)conn storeFactory:(PersistentModelStoreFactory *)sf;

@end

@interface AMQPSendOperation : NSOperation

@property (nonatomic, retain) NSManagedObjectID* messageId;
@property (nonatomic, retain) AMQPSender* sender;

- (id)initWithMessageId:(NSManagedObjectID *)msgId andSender:(AMQPSender *)sender;
- (void) send: (MEncodedMessage*) msg;

@end
