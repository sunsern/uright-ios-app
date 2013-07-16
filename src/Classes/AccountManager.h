//
//  AccountManager.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/15/13.
//
//

#import <Foundation/Foundation.h>

@interface AccountManager : NSObject

+ (BOOL)loginAsUsername:(NSString *)username password:(NSString *)password;
+ (void)logout;

@end
