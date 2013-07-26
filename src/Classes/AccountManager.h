//
//  AccountManager.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/15/13.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface AccountManager : NSObject

+ (void)loginAsParseUser:(PFUser *)user onComplete:(void(^)(BOOL))completeBlock;

+ (void)logout:(void(^)(void))completeBlock;

@end
