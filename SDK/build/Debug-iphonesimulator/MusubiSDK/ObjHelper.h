//
//  ObjHelper.h
//  musubi
//
//  Created by Willem Bult on 3/29/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kObjFieldTargetHash @"target_hash"
#define kObjFieldTargetRelation @"target_relation"
#define kObjFieldMimeType @"mimeType"
#define kObjFieldLocalUri @"localUri"
#define kObjFieldSharedKey @"sharedKey"
#define kObjFieldHtml @"__html"
#define kObjFieldText @"__text"
#define kObjFieldStatusText @"text"
#define kObjFieldRenderMode @"__render_mode"

#define kObjFieldRelationParent @"parent"
#define kObjFieldRenderModeLatest @"latest"

@class Obj, MObj, MFeed, MApp, PersistentModelStore, MIdentity;

@interface ObjHelper : NSObject

+ (BOOL) isRenderable: (Obj*) obj;
+ (MObj*) sendObj:(Obj *)obj toFeed:(MFeed *)feed fromApp: (MApp*) app usingStore: (PersistentModelStore*) store;
+ (MObj*) sendObj:(Obj *)obj toFeed:(MFeed *)feed asIdentity:(MIdentity*)ownedId fromApp: (MApp*) app usingStore: (PersistentModelStore*) store;

@end
