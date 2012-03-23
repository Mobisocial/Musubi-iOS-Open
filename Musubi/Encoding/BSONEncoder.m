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
//  BSONEncoder.m
//  Musubi
//
//  Created by Willem Bult on 2/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BSONEncoder.h"
#import "bson.h"
#import "Recipient.h"

@implementation BSONEncoder

void err_handler() {
    @throw [NSException exceptionWithName:@"Corrupted" reason:@"Message could not be decoded" userInfo:nil];
}


+ (NSData *)encodeMessage:(Message *)m {
    bson b;
    bson_init(&b);
    
    bson_append_int(&b, "v", m.v);
    
    bson_append_start_object(&b, "s");
    bson_append_binary(&b, "i", 128, [[m.s i] bytes], [[m.s i] length]);
    bson_append_binary(&b, "d", 128, [[m.s d] bytes], [[m.s d] length]);
    bson_append_finish_object(&b);
    
    bson_append_binary(&b, "i", 128, [m.i bytes], [m.i length]);
    bson_append_bool(&b, "l", m.l);
    bson_append_binary(&b, "a", 128, [m.a bytes], [m.a length]);

    bson_append_start_array(&b, "r");
    char* i = malloc(sizeof(char) * 2);
    i[0] = '0';
    i[1] = 0;
    
    for (Recipient* r in m.r) {
        bson_append_start_object(&b, i);
        bson_append_binary(&b, "i", 128, [r.i bytes], [r.i length]);
        bson_append_binary(&b, "k", 128, [r.k bytes], [r.k length]);
        bson_append_binary(&b, "s", 128, [r.s bytes], [r.s length]);
        bson_append_binary(&b, "d", 128, [r.d bytes], [r.d length]);
        bson_append_finish_object(&b);

        i[0]++;
    }
    bson_append_finish_array(&b);
    
    bson_append_binary(&b, "d", 128, [m.d bytes], [m.d length]);
    
    bson_finish(&b);
    
    NSData* raw = [NSData dataWithBytes:b.data length:b.dataSize];
    
    bson_destroy(&b);
    
    return raw;
}


+ (Message *)decodeMessage:(NSData *)data {
    set_bson_err_handler(err_handler);
    
    bson b, s, r;
    bson_iterator iter, iter2, iter3;
    bson_init_finished_data(&b, (char*)[data bytes]);
    
    
    Message* m = [[[Message alloc] init] autorelease];
    
    
    bson_find(&iter, &b, "v");
    [m setV: bson_iterator_int(&iter)];
    
    bson_find(&iter, &b, "s");
    
    // Read sender
    bson_iterator_subobject(&iter, &s);
    
    Sender* sender = [[[Sender alloc] init] autorelease];
    [m setS: sender];
    bson_find(&iter2, &s, "i");
    [sender setI:[NSData dataWithBytes:bson_iterator_bin_data(&iter2) length:bson_iterator_bin_len(&iter2)]];
    bson_find(&iter2, &s, "d");
    [sender setD:[NSData dataWithBytes:bson_iterator_bin_data(&iter2) length:bson_iterator_bin_len(&iter2)]];
    
    bson_find(&iter, &b, "i");
    [m setI:[NSData dataWithBytes:bson_iterator_bin_data(&iter) length:bson_iterator_bin_len(&iter)]];
    bson_find(&iter, &b, "l");
    [m setL: bson_iterator_bool(&iter)];
    bson_find(&iter, &b, "a");
    [m setA:[NSData dataWithBytes:bson_iterator_bin_data(&iter) length:bson_iterator_bin_len(&iter)]];
    
    bson_find(&iter, &b, "r");
    bson_iterator_subiterator(&iter, &iter2);
    
    NSMutableArray* rcpts = [NSMutableArray array];
    [m setR: rcpts];
    
    while (true) {
        bson_iterator_next(&iter2);
        if (!bson_iterator_more(&iter2))
            break;
        
        bson_iterator_subobject(&iter2, &r);
        
        Recipient* recipient = [[[Recipient alloc] init] autorelease];
        [rcpts addObject: recipient];
        
        bson_find(&iter3, &r, "i");
        [recipient setI:[NSData dataWithBytes:bson_iterator_bin_data(&iter3) length:bson_iterator_bin_len(&iter3)]];
        bson_find(&iter3, &r, "k");
        [recipient setK:[NSData dataWithBytes:bson_iterator_bin_data(&iter3) length:bson_iterator_bin_len(&iter3)]];
        bson_find(&iter3, &r, "s");
        [recipient setS:[NSData dataWithBytes:bson_iterator_bin_data(&iter3) length:bson_iterator_bin_len(&iter3)]];
        bson_find(&iter3, &r, "d");
        [recipient setD:[NSData dataWithBytes:bson_iterator_bin_data(&iter3) length:bson_iterator_bin_len(&iter3)]];
    }
    
    
    bson_find(&iter, &b, "d");
    [m setD:[NSData dataWithBytes:bson_iterator_bin_data(&iter) length:bson_iterator_bin_len(&iter)]];
    
    return m;
}

+ (NSData *)encodeSecret:(Secret *)s {
    bson b;
    bson_init(&b);
    
    bson_append_binary(&b, "h", 128, [s.h bytes], [s.h length]);
    bson_append_long(&b, "q", s.q);
    bson_append_binary(&b, "k", 128, [s.k bytes], [s.k length]);

    bson_finish(&b);
    
    NSData* raw = [NSData dataWithBytes:b.data length:b.dataSize];
    
    bson_destroy(&b);
    
    return raw;
}

+ (Secret *)decodeSecret:(NSData *)data {
    bson b;
    bson_iterator iter;
    bson_init_finished_data(&b, (char*)[data bytes]);

    Secret* s = [[[Secret alloc] init] autorelease];

    bson_find(&iter, &b, "h");
    [s setH:[NSData dataWithBytes:bson_iterator_bin_data(&iter) length:bson_iterator_bin_len(&iter)]];
    
    bson_find(&iter, &b, "q");
    [s setQ: bson_iterator_long(&iter)];
    
    bson_find(&iter, &b, "k");
    [s setK:[NSData dataWithBytes:bson_iterator_bin_data(&iter) length:bson_iterator_bin_len(&iter)]];

    return s;
}

+ (NSData *)encodeObj:(PreparedObj *)o {
    bson b;
    bson_init(&b);
    
    if (o.feedType)
        bson_append_int(&b, "feedType", o.feedType);
    if (o.feedCapability)
        bson_append_binary(&b, "feedCapability", 128, [o.feedCapability bytes], [o.feedCapability length]);
    if (o.appId)
        bson_append_string(&b, "appId", [o.appId cStringUsingEncoding:NSUTF8StringEncoding]);
    if (o.timestamp)
        bson_append_long(&b, "timestamp", o.timestamp);
    if (o.type)
        bson_append_string(&b, "type", [o.type cStringUsingEncoding:NSUTF8StringEncoding]);
    if (o.jsonSrc)
        bson_append_string(&b, "jsonSrc", [o.jsonSrc cStringUsingEncoding:NSUTF8StringEncoding]);
    if (o.raw)
        bson_append_binary(&b, "raw", 128, [o.raw bytes], [o.raw length]);
    
    bson_finish(&b);
    
    NSData* raw = [NSData dataWithBytes:b.data length:b.dataSize];
    
    bson_destroy(&b);
    
    return raw;
}

+ (PreparedObj *)decodeObj:(NSData *)data {
    bson b;
    bson_iterator iter;
    bson_init_finished_data(&b, (char*)[data bytes]);
    
    PreparedObj* o = [[[PreparedObj alloc] init] autorelease];
    int type;
    
    type = bson_find(&iter, &b, "feedType");
    if (type != 6)
        [o setFeedType: bson_iterator_int(&iter)];

    type = bson_find(&iter, &b, "feedCapability");
    if (type != 6)
        [o setFeedCapability:[NSData dataWithBytes:bson_iterator_bin_data(&iter) length:bson_iterator_bin_len(&iter)]];

    type = bson_find(&iter, &b, "appId");
    if (type != 6)
        [o setAppId:[NSString stringWithCString:bson_iterator_string(&iter) encoding:NSUTF8StringEncoding]];

    type = bson_find(&iter, &b, "timestamp");
    if (type != 6)
        [o setTimestamp: bson_iterator_long(&iter)];
    
    type = bson_find(&iter, &b, "type");
    if (type != 6)
        [o setType:[NSString stringWithCString:bson_iterator_string(&iter) encoding:NSUTF8StringEncoding]];
    
    type = bson_find(&iter, &b, "jsonSrc");
    if (type != 6)
        [o setJsonSrc:[NSString stringWithCString:bson_iterator_string(&iter) encoding:NSUTF8StringEncoding]];
    
    type = bson_find(&iter, &b, "raw");
    if (type != 6)
        [o setRaw:[NSData dataWithBytes:bson_iterator_bin_data(&iter) length:bson_iterator_bin_len(&iter)]];
    
    return o;
}

@end
