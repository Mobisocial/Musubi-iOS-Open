//
//  FileObj.h
//  musubi
//
//  Created by Ben Dodson on 6/1/12.
//  Copyright (c) 2012 Stanford University. All rights reserved.
//

#import "Obj.h"
#define kObjTypeFile @"file"
#define kObjFieldFilename @"filename"
#define kObjFieldFilesize @"filesize"

@interface FileObj : Obj<RenderableObj>

@end
