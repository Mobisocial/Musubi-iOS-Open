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

@implementation RabbitMQMessengerService

@synthesize messageFormat, identity;

- (id)init {
    self = [super init];
    if (self != nil) {
        [self setMessageFormat: [MessageFormat defaultMessageFormat]];
        [self setIdentity: [Identity sharedInstance]];
    }
    
    return self;
}

- (NSString*) queueForKey: (OpenSSLPublicKey*) key {
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

- (NSString*) routeForKeys: (NSArray*) keys {
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

- (void) sendMessage: (OutgoingMessage*) msg {
    
    amqp_connection_state_t conn = amqp_new_connection();
    
    // Open socket to AMQP server
    int sockfd;
    die_on_error(sockfd = amqp_open_socket("pepperjack.stanford.edu", 5672), "Opening socket");
    amqp_set_sockfd(conn, sockfd);
    
    // Login to server using default username/password
    die_on_amqp_error(amqp_login(conn, "/", 0, 131072, 30, AMQP_SASL_METHOD_PLAIN, "guest", "guest"), "Logging in");
    
    // Open channel
    amqp_channel_open(conn, 1);
    die_on_amqp_error(amqp_get_rpc_reply(conn), "Opening channel");
    
    // Declare exchange using destination keys
    NSString* exchange = [self routeForKeys: [msg toPublicKeys]];
    const char* cExchange = [exchange cStringUsingEncoding:NSUTF8StringEncoding];
    amqp_exchange_declare(conn, 1, amqp_cstring_bytes(cExchange), amqp_cstring_bytes("fanout"), 0, 0, amqp_empty_table);
    die_on_amqp_error(amqp_get_rpc_reply(conn), "Declaring exchange");
    
    // Declare queues and bind exchange for every recipient
    for (NSString* key in [msg toPublicKeys]) {
        // Determine queue name using recipient's public key
        OpenSSLPublicKey* rsaKey = [[OpenSSLPublicKey alloc] initWithEncoded: [key decodeBase64]];
        NSString* queueName = [self queueForKey:rsaKey];
        const char* cQueueName = [queueName cStringUsingEncoding:NSUTF8StringEncoding];
        
        // Declare queue
        amqp_queue_declare(conn, 1, amqp_cstring_bytes(cQueueName), 0, 1, 0, 0, amqp_empty_table);
        die_on_amqp_error(amqp_get_rpc_reply(conn), "Declaring queue");
        
        // Bind queue to exchange
        amqp_queue_bind(conn, 1, amqp_cstring_bytes(cQueueName), amqp_cstring_bytes(cExchange), amqp_cstring_bytes(""),
                        amqp_empty_table);
        die_on_amqp_error(amqp_get_rpc_reply(conn), "Binding queue");
    }

    // Encode message using message format
    NSData* encoded = [messageFormat encodeMessage: msg withKeyPair:[identity keyPair]];
    amqp_bytes_t cyphered;
    cyphered.bytes = (void*) [encoded bytes];
    cyphered.len = [encoded length];
    
    // Publish the encoded message on the exchange
    die_on_error(amqp_basic_publish(conn,
                               1,
                               amqp_cstring_bytes(cExchange),
                               amqp_cstring_bytes(""),
                               1,
                               0,
                               NULL,
                               cyphered),
                     "Publishing");
    
    // Close channel and connection
    die_on_amqp_error(amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS), "Closing channel");
    die_on_amqp_error(amqp_connection_close(conn, AMQP_REPLY_SUCCESS), "Closing connection");
    die_on_error(amqp_destroy_connection(conn), "Ending connection");
    
    NSLog(@"Sent message: %@", msg);
    return;
}

- (void) runWithPublicKey: (NSString*) pubKey {
    const char* exchange = [pubKey cStringUsingEncoding:NSUTF8StringEncoding];
    
    amqp_connection_state_t conn = amqp_new_connection();

    int sockfd;
    die_on_error(sockfd = amqp_open_socket("pepperjack.stanford.edu", 5672), "Opening socket");
    amqp_set_sockfd(conn, sockfd);
    
    die_on_amqp_error(amqp_login(conn, "/", 0, 131072, 30, AMQP_SASL_METHOD_PLAIN, "guest", "guest"), "Logging in");
    amqp_channel_open(conn, 1);
    die_on_amqp_error(amqp_get_rpc_reply(conn), "Opening channel");
    
    amqp_queue_declare_ok_t *r = amqp_queue_declare(conn, 1, amqp_cstring_bytes(exchange), 0, 0, 0, 1,
                                                    amqp_empty_table);
    die_on_amqp_error(amqp_get_rpc_reply(conn), "Declaring queue");
    
    amqp_bytes_t queuename = amqp_bytes_malloc_dup(r->queue);
    if (queuename.bytes == NULL) {
        fprintf(stderr, "Out of memory while copying queue name");
        return;
    }
    
    amqp_basic_consume(conn, 1, amqp_cstring_bytes(exchange), amqp_empty_bytes, 0, 0, 0, amqp_empty_table);
    die_on_amqp_error(amqp_get_rpc_reply(conn), "Consuming");
    
    
    amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS);
    amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
    amqp_destroy_connection(conn);
}

@end
