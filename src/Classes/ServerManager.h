//
//  ServerManager.h
//  Handwriting
//
//  Created by Sunsern Cheamanunkul on 6/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SessionData;
@class ExampleSet;

@interface ServerManager : NSObject

+ (NSDictionary *)fetchDataForUsername:(NSString *)username password:(NSString *)password;
+ (NSDictionary *)submitSessionData:(SessionData *)data;
+ (BOOL)isOnline;

@end
