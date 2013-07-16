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

+ (int)getUserIDFromUsername:(NSString *)username
                    password:(NSString *)password;

+ (int)createAccountForUsername:(NSString *)username
                       password:(NSString *)password
                          email:(NSString *)email
                       fullname:(NSString *)fullname;

+ (NSDictionary *)fetchLanguageData;

+ (NSDictionary *)fetchClassifiers;

+ (BOOL)uploadSessionData:(SessionData *)data;

@end
