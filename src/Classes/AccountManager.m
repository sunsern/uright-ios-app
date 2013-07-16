//
//  AccountManager.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/15/13.
//
//

#import "AccountManager.h"
#import "ServerManager.h"

@implementation AccountManager

+ (BOOL)loginAsUsername:(NSString *)username password:(NSString *)password {
    NSDictionary *result = [ServerManager getUserIdFromUsername:username password:password];
    // successful
    if (result && [result[@"login_result"] isEqualToString:@"OK"]) {
        GlobalStorage *gs = [GlobalStorage sharedInstance];
        [gs switchActiveUser:[result[@"user_id"] intValue]];
        return YES;
    } else {
        return NO;
    }
}

+ (void)logout {
    GlobalStorage *gs = [GlobalStorage sharedInstance];
    [gs switchActiveUser:kURGuestUserID];
}

@end
