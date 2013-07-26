//
//  ServerManager.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 6/1/12.
//

#import <Foundation/Foundation.h>

@class SessionData;

@interface ServerManager : NSObject

/**
 Checks if there is internet connection.
 */
+ (BOOL)isOnline;

/**
 Returns userID > 0 if success, otherwise returns 0.
 */
+ (int)loginWithUsername:(NSString *)username
                password:(NSString *)password;

/**
 Returns the new userID > 0, otherwise returns 0.
 */
+ (int)createAccountForUsername:(NSString *)username
                       password:(NSString *)password
                          email:(NSString *)email
                       fullname:(NSString *)fullname;

+ (NSArray *)fetchCharsets;

+ (NSDictionary *)fetchProtosets:(int)userID;

+ (NSDictionary *)announcement;

+ (BOOL)uploadSessionData:(SessionData *)data;

@end
