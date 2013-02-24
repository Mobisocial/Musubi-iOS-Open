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




#import "AphidIdentityProvider.h"
#import "Musubi.h"

#import "NSData+Base64.h"
#import "AccountManager.h"
#import "IdentityManager.h"

#import "MAccount.h"
#import "MIdentity.h"
#import "SBJSON.h"
#import "Authorities.h"

#import "IBEncryptionScheme.h"

@implementation AphidIdentityProvider

@synthesize signatureScheme, encryptionScheme, identityManager, knownTokens;

- (id) init {
    self = [super init];
    if (self != nil) {
        self.encryptionScheme = [IBEncryptionScheme alloc];
        self.signatureScheme = [IBSignatureScheme alloc];
        
        [self setIdentityManager: [[IdentityManager alloc] initWithStore: [[Musubi sharedInstance] newStore]]];
        
        [self setKnownTokens: [NSMutableDictionary dictionary]];
    }
    return self;
}


- (IBSignatureUserKey *)signatureKeyForIdentity:(IBEncryptionIdentity *)ident {
    if(ident.principal == nil) {
        ident = [identityManager ibEncryptionIdentityForHasedIdentity:ident];
        if (ident.principal == nil)
            @throw [NSException exceptionWithName:kMusubiExceptionInvalidRequest reason:@"Identity's principal must be known to request signature from Aphid" userInfo:nil];
    }

    return [[IBSignatureUserKey alloc] initWithRaw:[NSData data]];
}

- (IBEncryptionUserKey *)encryptionKeyForIdentity:(IBEncryptionIdentity *)ident {
    if(ident.principal == nil) {
        ident = [identityManager ibEncryptionIdentityForHasedIdentity:ident];
        if (ident.principal == nil)
            @throw [NSException exceptionWithName:kMusubiExceptionInvalidRequest reason:@"Identity's principal must be known to request encryption from Aphid" userInfo:nil];
    }
    
    return [[IBEncryptionUserKey alloc] initWithRaw:[NSData data]];
}

- (void) setToken: (NSString*) token forUser: (NSString*) principal withAuthority: (int) authority {
    [knownTokens setObject:token forKey:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedChar:authority], principal, nil]];
}

@end


