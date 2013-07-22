//
//  ServerManager.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 6/1/12.
//

#import <Foundation/Foundation.h>

@class SessionData;

@interface ServerManager : NSObject

+ (BOOL)isOnline;

+ (int)userIDFromUsername:(NSString *)username
                 password:(NSString *)password;

+ (int)createAccountForUsername:(NSString *)username
                       password:(NSString *)password
                          email:(NSString *)email
                       fullname:(NSString *)fullname;

+ (NSArray *)fetchCharsets;

+ (NSDictionary *)fetchProtosets:(int)userID;

+ (BOOL)uploadSessionData:(SessionData *)data;

+ (NSDictionary *)announcement;

@end
