//
//  ServerManager.h
//  Handwriting
//
//  Created by Sunsern Cheamanunkul on 6/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SessionData;

@interface ServerManager : NSObject

+ (void)showConnectionError:(NSString *)message;
+ (NSDictionary *)fetchDataForUsername:(NSString *)username password:(NSString *)password;
+ (NSDictionary *)submitSessionData:(SessionData *)data;
+ (BOOL)isOnline;
+ (void)synchronizeData;

@end
