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
//  EncodingTest.h
//  Musubi
//
//  Created by Willem Bult on 2/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//  Logic unit tests contain unit test code that is designed to be linked into an independent test executable.
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

#import "TransientTransportDataProvider.h"
#import "MusubiAppTest.h"

@interface EncodingTestBlacklistProvider : NSObject<BlackListProvider> {
    NSArray* blacklist;
}

@property (nonatomic, retain) NSArray* blacklist;
- (id) initWithBlacklist: (NSArray*) list;

@end

@interface EncodingTestSignatureController : NSObject<SignatureController> {
    uint64_t t;
}
@end
    
@interface EncodingTestEncryptionController : NSObject<EncryptionController> {
    uint64_t t;
}
@end

@interface EncodingTest : MusubiAppTest

@end
