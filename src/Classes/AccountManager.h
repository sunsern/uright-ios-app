//
//  AccountManager.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/15/13.
//
//

#import <Foundation/Foundation.h>

@interface AccountManager : NSObject

+ (void)initializeFacebookSession;
+ (void)loginAsCurrentFacebookUser:(void(^)(BOOL))completeBlock;
+ (void)loginAsUsername:(NSString *)username password:(NSString *)password
             onComplete:(void(^)(BOOL))completeBlock;
+ (void)logout:(void(^)(void))completeBlock;

@end
