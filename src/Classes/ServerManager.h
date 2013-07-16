//
//  ServerManager.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 6/1/12.
//

#import <Foundation/Foundation.h>

@class SessionData;

@interface ServerManager : NSObject

+ (void)showConnectionError:(NSString *)message;

+ (NSDictionary *)fetchDataForUsername:(NSString *)username password:(NSString *)password;

+ (NSDictionary *)submitSessionData:(SessionData *)data;

+ (BOOL)isOnline;

+ (void)synchronizeData;

+ (int)createAccountForUsername:(NSString *)username
                        password:(NSString *)password
                           email:(NSString *)email
                        fullname:(NSString *)fullname;

+ (NSDictionary *)getUserIdFromUsername:(NSString *)username
                               password:(NSString *)password;

@end
