//
//  AccountManager.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/15/13.
//
//
#import <Parse/Parse.h>
#import <FacebookSDK/FacebookSDK.h>

#import "AccountManager.h"
#import "ServerManager.h"

@implementation AccountManager

+ (void)loginAsParseUser:(PFUser *)user onComplete:(void(^)(BOOL))completeBlock {
    // FB user
    if ([PFFacebookUtils session].isOpen) {
        
        // Request data
        [[FBRequest requestForMe] startWithCompletionHandler:
         ^(FBRequestConnection *connection,
           NSDictionary <FBGraphUser> *fbuser,
           NSError *error) {
             if (!error) {
                 
                 // Create username and password
                 NSString *username = [NSString stringWithFormat:@"FB_%@",fbuser.username];
                 NSString *password = fbuser.id;
                 
                 // Attemp to login
                 int userID = [ServerManager userIDFromUsername:username
                                                          password:password];
                 
                 if (userID != kURGuestUserID) {
                     // Success!
                     GlobalStorage *gs = [GlobalStorage sharedInstance];
                     [gs switchActiveUser:userID onComplete:^{
                         Userdata *ud = [[GlobalStorage sharedInstance] activeUserdata];
                         ud.username = username;
                         completeBlock(YES);
                     }];
                 } else {
                     // User not found. Create a new one!
                     int newUserID = [ServerManager createAccountForUsername:username
                                                                    password:password
                                                                       email:fbuser[@"email"]
                                                                    fullname:fbuser.name];
                     if (newUserID != kURGuestUserID) {
                         // Success!
                         GlobalStorage *gs = [GlobalStorage sharedInstance];
                         [gs switchActiveUser:newUserID onComplete:^{
                             Userdata *ud = [[GlobalStorage sharedInstance] activeUserdata];
                             ud.username = username;
                             completeBlock(YES);
                         }];
                     } else {
                         // ERROR
                         completeBlock(NO);
                     }
                 }
             } else {
                 // ERROR
                 completeBlock(NO);
             }
         }];
    }
    else {
        //  Non-FB user
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            // Create username and password
            NSString *username = [NSString stringWithFormat:@"PF_%@",user.username];
            NSString *password = user.objectId;
            NSString *email = user.email;
            
            // Attemp to login
            int userID = [ServerManager userIDFromUsername:username
                                                     password:password];
            
            if (userID != kURGuestUserID) {
                // Success!
                GlobalStorage *gs = [GlobalStorage sharedInstance];
                [gs switchActiveUser:userID onComplete:^{
                    Userdata *ud = [[GlobalStorage sharedInstance] activeUserdata];
                    ud.username = username;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completeBlock(YES);
                    });
                }];
            } else {
                // User not found. Create a new one!
                int newUserID = [ServerManager createAccountForUsername:username
                                                               password:password
                                                                  email:email
                                                               fullname:@""];
                if (newUserID != kURGuestUserID) {
                    // Success!
                    GlobalStorage *gs = [GlobalStorage sharedInstance];
                    [gs switchActiveUser:newUserID onComplete:^{
                        Userdata *ud = [[GlobalStorage sharedInstance] activeUserdata];
                        ud.username = username;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            completeBlock(YES);
                        });
                    }];
                } else {
                    // ERROR
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completeBlock(NO);
                    });
                }
            }
        });
    }
}

+ (void)logout:(void(^)(void))completeBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        GlobalStorage *gs = [GlobalStorage sharedInstance];
        [gs switchActiveUser:kURGuestUserID onComplete:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock();
            });
        }];
    });
}

@end
