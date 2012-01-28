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
//  RabbitMQMessengerService.m
//  musubi
//
//  Created by Willem Bult on 10/14/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "RabbitMQMessengerService.h"

@implementation RabbitMQQueuedMessage 

@synthesize message, recipients;

@end

@implementation RabbitMQMessengerService

@synthesize identity, listener, queue, connLock;

- (id)initWithListener:(id<TransportListener>) l {
    self = [super init];
    if (self != nil) {
        [self setIdentity: [Identity sharedInstance]];
        [self setListener: l];
        [self setQueue: [NSMutableArray arrayWithCapacity:10]];
        [self setConnLock: [[[NSLock alloc] init] autorelease]];
    }
    
    return self;
}


- (NSData*) consumeMessageFromConn: (amqp_connection_state_t) conn {
    amqp_frame_t frame;
    int result;
    size_t body_received;
    size_t body_target;
    
    amqp_maybe_release_buffers(conn);
    
    result = amqp_simple_wait_frame(conn, &frame);
    if (result < 0) {
        @throw [NSException exceptionWithName:@"AMQPException" reason:@"Got error waiting for frame" userInfo:nil];
    }

    if (frame.frame_type != AMQP_FRAME_METHOD) {
        return nil;
    }
    
    if (frame.payload.method.id != AMQP_BASIC_DELIVER_METHOD) {
        return nil;
    }
    
    delivery = (amqp_basic_deliver_t*) frame.payload.method.decoded;
    
    result = amqp_simple_wait_frame(conn, &frame);
    if (result < 0) {
        @throw [NSException exceptionWithName:@"AMQPException" reason:@"Got error waiting for frame" userInfo:nil];
    }
    
    if (frame.frame_type != AMQP_FRAME_HEADER) {
        @throw [NSException exceptionWithName:@"AMQPException" reason:@"Expected frame header but got something else" userInfo:nil];
    }
    
    body_target = frame.payload.properties.body_size;
    body_received = 0;
    
    NSMutableData* messageData = [NSMutableData data];
    
    while (body_received < body_target) {
        result = amqp_simple_wait_frame(conn, &frame);
        if (result < 0) {
            @throw [NSException exceptionWithName:@"AMQPException" reason:@"Got error waiting for frame" userInfo:nil];
        }
        
        if (frame.frame_type != AMQP_FRAME_BODY) {
            @throw [NSException exceptionWithName:@"AMQPException" reason:@"Expected body" userInfo:nil];
        }
        
        body_received += frame.payload.body_fragment.len;
        [messageData appendBytes:frame.payload.body_fragment.bytes length:frame.payload.body_fragment.len];
        assert(body_received <= body_target);
    }
    
    return messageData;
}

- (NSData*) dataFromMessage: (EncodedMessage*) msg {
    NSMutableData* data = [NSMutableData data];
    
    uint16_t len = CFSwapInt16HostToBig([[msg signature] length]);
    [data appendBytes:&len length:sizeof(len)];
    [data appendData: [msg signature]];
    [data appendData: [msg message]];

    return data;
}

- (EncodedMessage*) messageFromData: (NSData*) data {
    const void* ptr = [data bytes];

    uint16_t len = CFSwapInt16BigToHost(*(uint16_t*)ptr);
    ptr += sizeof(len);
    
    NSData* signature = [NSData dataWithBytes:ptr length:len];
    ptr += len;
    
    NSData* payload = [NSData dataWithBytes:ptr length:[data length]-len];
    
    EncodedMessage* encoded = [[[EncodedMessage alloc] init] autorelease];
    [encoded setSignature:signature];
    [encoded setMessage:payload];
    
    return encoded;
}

- (void)receive {
    [inLock lock];
    
    while (true) {
        amqp_connection_state_t conn = [self openConnection];
        
        if (conn == nil) {
            break;
        }
        
        @try {
            while (true) {
                
                // Open channel
                amqp_channel_open(conn, 1);
                [RabbitMQMessengerService amqpCheckReplyForConn:conn inContext:@"Opening channel"];
                
                // Declare our queue (by public key)
                NSString* queueName = [RabbitMQMessengerService queueForKey:[[identity deviceKey] publicKey]];
                const char* cQueueName = [queueName cStringUsingEncoding:NSUTF8StringEncoding];
                
                amqp_queue_declare_ok_t *r = amqp_queue_declare(conn, 1, amqp_cstring_bytes(cQueueName), 0, 1, 0, 0, amqp_empty_table);
                [RabbitMQMessengerService amqpCheckReplyForConn:conn inContext:@"Declaring queue"];
                
                // Get the name of the queue
                amqp_bytes_t queuename = amqp_bytes_malloc_dup(r->queue);
                if (queuename.bytes == NULL) {
                    @throw [NSException exceptionWithName:@"AMQPException" reason:@"Out of memory while copying queue name" userInfo:nil];
                }
                
                // Consume from the queue
                amqp_basic_consume(conn, 1, queuename, amqp_empty_bytes, 0, 0, 0, amqp_empty_table);
                [RabbitMQMessengerService amqpCheckReplyForConn:conn inContext:@"Basic consume"];
                
                @try {
                    while (true) {
                        
                        // Keep reading messageg
                        NSData* incoming = [self consumeMessageFromConn:conn];
                        
                        if (incoming != nil) {
                            
                            EncodedMessage* msg = [[self messageFromData:incoming] retain];

                            @try {
                                NSLog(@"[RabbitMQMessengerService] Incoming message: %@", msg);
                                
                                int res = [listener handleIncoming:msg];
                                if (res) {
                                    amqp_basic_ack(conn, 1, delivery->delivery_tag, FALSE);
                                } else {
                                    amqp_basic_reject(conn, 1, delivery->delivery_tag, FALSE);
                                }
                            }
                            @catch (NSException *exception) {
                                NSLog(@"Message exception: %@", exception);
                                amqp_basic_reject(conn, 1, delivery->delivery_tag, FALSE);
                            }
                            @finally {
                                [msg release];
                            }
                        }
                    }
                } @catch (NSException* exception) {
                    NSLog(@"Transport exception: %@", exception);
                } @finally {
                    // close the channel
                    amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS);
                }
            }
            
            amqp_connection_close(conn, AMQP_REPLY_SUCCESS);

        } @catch (NSException* exception) {
            NSLog(@"Exception: %@", exception);
        } @finally {
            amqp_destroy_connection(conn);
        }
    }
    
    
    [inLock unlockWithCondition:1];
}

- (void) sendData: (NSData*) data toKeys: (NSArray*) keys onConn: (amqp_connection_state_t) conn {
    // Declare exchange using destination keys
    NSString* exchange = [RabbitMQMessengerService routeForKeys: keys];
    const char* cExchange = [exchange cStringUsingEncoding:NSUTF8StringEncoding];
    amqp_exchange_declare(conn, 1, amqp_cstring_bytes(cExchange), amqp_cstring_bytes("fanout"), 0, 0, amqp_empty_table);
    
    NSLog(@"Recipients: %@", keys);
    // Declare queues and bind exchange for every recipient
    for (NSString* key in keys) {
        // Determine queue name using recipient's public key
        OpenSSLPublicKey* rsaKey = [[[OpenSSLPublicKey alloc] initWithEncoded: [key decodeBase64]] autorelease];
        NSString* queueName = [RabbitMQMessengerService queueForKey:rsaKey];
        const char* cQueueName = [queueName cStringUsingEncoding:NSUTF8StringEncoding];
        
        // Declare queue
        amqp_queue_declare(conn, 1, amqp_cstring_bytes(cQueueName), 0, 1, 0, 0, amqp_empty_table);
        [RabbitMQMessengerService amqpCheckReplyForConn:conn inContext:@"Declaring queue"];
        
        // Bind queue to exchange
        amqp_queue_bind(conn, 1, amqp_cstring_bytes(cQueueName), amqp_cstring_bytes(cExchange), amqp_cstring_bytes(""),
                        amqp_empty_table);
        [RabbitMQMessengerService amqpCheckReplyForConn:conn inContext:@"Binding queue"];
    }
    
    // Publish the data on the exchange 
    amqp_bytes_t message;
    message.bytes = (void*) [data bytes];
    message.len = [data length];
    
    int result = amqp_basic_publish(conn,
                                    1,
                                    amqp_cstring_bytes(cExchange),
                                    amqp_cstring_bytes(""),
                                    1,
                                    0,
                                    NULL,
                                    message);
    if (result > 0) {
        @throw [NSException exceptionWithName:@"AMQPException" reason:@"Error while publishing" userInfo:nil];
    }
}

- (void)send {
    [outLock lock];
    while (true) {
        amqp_connection_state_t conn = [self openConnection];
        @try {
            // Open channel
            amqp_channel_open(conn, 1);
            [RabbitMQMessengerService amqpCheckReplyForConn:conn inContext:@"Opening channel"];
            
            //@try {
                // keep sending and receiving messages
                while (true) {
                    if ([queue count] > 0) {
                        RabbitMQQueuedMessage* queuedMsg = [queue objectAtIndex:0];
                        
                        NSLog(@"[RabbitMQMessengerService] Sending message: %@", [queuedMsg message]);
                        
                        // send message
                        [self sendData:[self dataFromMessage: [queuedMsg message]] toKeys:[queuedMsg recipients] onConn:conn];
                        [queue removeObjectAtIndex:0];
                    }
                    
                    // sleep 100 ms
                    [NSThread sleepForTimeInterval:3];
                }        
            //} @catch (NSException* exception) {
            //    NSLog(@"TransportException: %@", exception);                    
            //} @finally {
            //}

            // close the channel
            amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS);
            amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
            amqp_destroy_connection(conn);
        } @catch (NSException* exception) {
            NSLog(@"MessageException: %@", exception);
        } @finally {
            
        }
    }
 

    [outLock unlockWithCondition:1];
}

- (void)sendMessage:(EncodedMessage *)msg to:(NSArray *)recipients {
    RabbitMQQueuedMessage* queuedMsg = [[[RabbitMQQueuedMessage alloc] init] autorelease];
    [queuedMsg setMessage:msg];
    [queuedMsg setRecipients:recipients];
    [queue addObject:queuedMsg];
}


- (void) run {
    inLock = [[NSConditionLock alloc] initWithCondition:0];
    outLock = [[NSConditionLock alloc] initWithCondition:0];
    
    while (true) {
        // Run the in / out threads
        NSThread *inThread = [[NSThread alloc] initWithTarget:self
                                                     selector:@selector(receive)
                                                       object:nil];
        
        NSThread *outThread = [[NSThread alloc] initWithTarget:self
                                                      selector:@selector(send)
                                                       object:nil];
    
        [inThread start];
        [outThread start];
        
        [outLock lockWhenCondition:1];
        NSLog(@"Outgoing done");

        [inLock lockWhenCondition:
         1];
        NSLog(@"Incoming done");

        [outLock unlock];
        [inLock unlock];
    }
    
    [outLock release];
    [inLock release];    
}

- (amqp_connection_state_t) openConnection {
    [connLock lock];
    NSLog(@"Connecting to AMQP");
    amqp_connection_state_t conn = amqp_new_connection();
    
    // Open socket to AMQP server
    int sockfd = amqp_open_socket("pepperjack.stanford.edu", 5672);
    if (sockfd < 0) {
        return nil;
    }
    amqp_set_sockfd(conn, sockfd);
    
    // Login to server using default username/password
    amqp_rpc_reply_t reply = amqp_login(conn, "/", 0, 131072, 30, AMQP_SASL_METHOD_PLAIN, "guest", "guest");
    
    /*if (reply.reply_type != AMQP_REPLY_SUCCESS) {
        NSLog(@"Login fail");
        amqp_destroy_connection(conn);
        return nil;
    }*/
    
    NSLog(@"Connected to AMQP");
    [connLock unlock];
    return conn;
}

+ (NSString*) routeForKeys: (NSArray*) keys {
    unsigned char digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1_CTX ctx;
    CC_SHA1_Init(&ctx);
    {
        for (NSString* key in keys) {
            const char* cKey = [key cStringUsingEncoding:NSUTF8StringEncoding];
            CC_SHA1_Update(&ctx, cKey, sizeof(cKey));
        }
    }
    CC_SHA1_Final(digest, &ctx);
    return [[NSData dataWithBytes: digest length:CC_SHA1_DIGEST_LENGTH] encodeBase64];
}

+ (NSString*) queueForKey: (OpenSSLPublicKey*) key {
    NSMutableData* bytes = [NSMutableData data];
    
    NSData* mod = [key modulus];
    NSData* exp = [key publicExponent];
    
    int seqByte = 255;
    uint16_t modLen = [mod length] + 1;
    uint16_t expLen = [exp length];
    
    [bytes appendBytes:&seqByte length:1];
    [bytes appendBytes:&modLen length:2];
    [bytes appendData:mod];
    [bytes appendBytes:&expLen length:1];
    [bytes appendData:exp];
    
    return [bytes encodeBase64];
}

+ (void) amqpCheckReplyForConn: (amqp_connection_state_t) c inContext: (NSString*) context {
    if (amqp_get_rpc_reply(c).reply_type != AMQP_RESPONSE_NORMAL) {
        @throw [NSException exceptionWithName:@"AMQPException" reason: [RabbitMQMessengerService amqpErrorMessageFor: amqp_get_rpc_reply(c) inContext: context] userInfo: nil];
    }
}

+ (NSString*) amqpErrorMessageFor: (amqp_rpc_reply_t) x inContext: (NSString*) context {
    switch (x.reply_type) {
        case AMQP_RESPONSE_NORMAL:
            return nil;
            
        case AMQP_RESPONSE_NONE:
            return [NSString stringWithFormat:@"%@: missing RPC reply type!", context];
            
        case AMQP_RESPONSE_LIBRARY_EXCEPTION:
            return [NSString stringWithFormat:@"%@: %s", context, amqp_error_string(x.library_error)];       
            
        case AMQP_RESPONSE_SERVER_EXCEPTION:
            switch (x.reply.id) {
                case AMQP_CONNECTION_CLOSE_METHOD: {
                    amqp_connection_close_t *m = (amqp_connection_close_t *) x.reply.decoded;
                    return [NSString stringWithFormat:@"%@: server connection error %d, message: %.*s", context,
                            m->reply_code,
                            (int) m->reply_text.len, (char *) m->reply_text.bytes];
                }
                case AMQP_CHANNEL_CLOSE_METHOD: {
                    amqp_channel_close_t *m = (amqp_channel_close_t *) x.reply.decoded;
                    return [NSString stringWithFormat:@"%@: server channel error %d, message: %.*s", context,
                            m->reply_code,
                            (int) m->reply_text.len, (char *) m->reply_text.bytes];
                }
                default:
                    return [NSString stringWithFormat:@"%@: unknown server error, method id 0x%08X", context,
                            x.reply.id];
            }
    }
    return nil;
}


@end