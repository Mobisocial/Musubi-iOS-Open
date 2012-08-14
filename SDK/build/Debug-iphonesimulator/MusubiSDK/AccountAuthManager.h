//
//  AccountAuthManager.h
//  Musubi
//
//  Created by Willem Bult on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MIdentity, MAccount, IdentityManager, IBEncryptionIdentity;

@protocol AccountAuthManagerDelegate

- (void) accountWithType: (NSString*) type isConnected: (BOOL) connected;

@end


@interface AccountAuthManager : NSObject {
    id<AccountAuthManagerDelegate> __weak delegate;
    NSOperationQueue* queue;
}

@property (nonatomic, weak) id<AccountAuthManagerDelegate> delegate;
@property (nonatomic) NSOperationQueue* queue;

- (id) initWithDelegate: (id<AccountAuthManagerDelegate>) d;

- (BOOL) isConnected: (NSString*) type;
- (void) checkStatus: (NSString*) type;
- (void) checkStatus: (NSString *)type withPrincipal: (NSString*) principal;
- (void) connect: (NSString*) type;
- (void) connect:(NSString *)type withPrincipal: (NSString*) principal;
- (void) disconnect: (NSString*) type;
- (void) disconnect:(NSString *)type withPrincipal: (NSString*) principal;
- (NSArray*) principalsForAccount: (NSString*) type;

// private
- (void) populateIdentity: (MIdentity*) mIdent fromIBEIdentity: (IBEncryptionIdentity*) ibeId andOriginal: (MIdentity*) original withManager: (IdentityManager*) identityManager andAccountName: (NSString*) accountName;
- (MAccount*) storeAccount: (NSString*) type name: (NSString*) name principal: (NSString*) principal;
- (BOOL) checkAccount: (NSString*) type name: (NSString*) name principal: (NSString*) principal;
- (void) onAccount: (NSString*) type isValid: (BOOL) valid;

@end
