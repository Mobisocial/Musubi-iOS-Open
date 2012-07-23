//
//  MApp.h
//  musubi
//
//  Created by MokaFive User on 5/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface MApp : NSManagedObject

@property (nonatomic, retain) NSString * appId;
@property (nonatomic, retain) NSData * icon;
@property (nonatomic, retain) NSString * manifestUri;
@property (nonatomic, retain) NSString * mimeTypes;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * packageName;
@property (nonatomic) NSTimeInterval refreshedAt;
@property (nonatomic, retain) NSData * smallIcon;

@end
