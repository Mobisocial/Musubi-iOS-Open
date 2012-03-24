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
//  AMQPTransport.h
//  Musubi
//
//  Created by Willem Bult on 3/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AMQPConnectionManager, AMQPSender, AMQPListener, PersistentModelStoreFactory;

@interface AMQPTransport : NSObject {
    AMQPConnectionManager* connMngrIn;
    AMQPConnectionManager* connMngrOut;

    AMQPSender* sender;
    AMQPListener* listener;
}

@property (nonatomic,retain) AMQPConnectionManager* connMngrIn;
@property (nonatomic,retain) AMQPConnectionManager* connMngrOut;

@property (nonatomic,retain) AMQPSender* sender;
@property (nonatomic,retain) AMQPListener* listener;

- (id) initWithStoreFactory: (PersistentModelStoreFactory*) storeFactory;

- (void) start;
- (void) stop;
- (void) restart;
- (BOOL) done;

@end
