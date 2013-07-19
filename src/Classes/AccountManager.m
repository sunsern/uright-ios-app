//
//  AccountManager.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/15/13.
//
//

#import <FacebookSDK/FacebookSDK.h>

#import "AccountManager.h"
#import "ServerManager.h"

@implementation AccountManager


+ (void)initializeFacebookSession {
    FBSession *session = [[FBSession alloc] init];
    [FBSession setActiveSession:session];
}

+ (void)loginAsCurrentFacebookUser:(void(^)(BOOL))completeBlock; {
    NSArray *permissions = @[@"email"];
    
    // Attempt to open the session. If the session is not open,
    // show the user the Facebook login UX
    [FBSession openActiveSessionWithReadPermissions:permissions
                                       allowLoginUI:YES
                                  completionHandler:^(FBSession *session,                                           FBSessionState status, NSError *error)
     {
         // Did something go wrong during login? I.e. did the user cancel?
         if (status == FBSessionStateClosedLoginFailed || status == FBSessionStateCreatedOpening) {
             
             // If so, just send them round the loop again
             [[FBSession activeSession] closeAndClearTokenInformation];
             [FBSession setActiveSession:nil];
             
             FBSession *session = [[FBSession alloc] init];
             [FBSession setActiveSession:session];
         } else {
             if (FBSession.activeSession.isOpen) {
                 
                 // Request data
                 [[FBRequest requestForMe] startWithCompletionHandler:
                  ^(FBRequestConnection *connection,
                    NSDictionary <FBGraphUser> *user,
                    NSError *error) {
                      if (!error) {
                          
                          // Create username and password
                          NSString *username = [NSString stringWithFormat:@"FB_%@",user.username];
                          NSString *password = user.id;
                        
                          // Attemp to login
                          int userID = [ServerManager getUserIDFromUsername:username
                                                                   password:password];
                          
                          if (userID != kURGuestUserID) {
                              GlobalStorage *gs = [GlobalStorage sharedInstance];
                              [gs switchActiveUser:userID onComplete:^{
                                  UserData *ud = [[GlobalStorage sharedInstance] activeUserData];
                                  ud.username = username;
                                  ud.password = password;
                                  completeBlock(YES);
                              }];
                          } else {
                              int newUserID = [ServerManager createAccountForUsername:username
                                                                             password:password
                                                                                email:user[@"email"]
                                                                             fullname:user.name];
                              if (newUserID != kURGuestUserID) {
                                  GlobalStorage *gs = [GlobalStorage sharedInstance];
                                  [gs switchActiveUser:newUserID onComplete:^{
                                      UserData *ud = [[GlobalStorage sharedInstance] activeUserData];
                                      ud.username = username;
                                      ud.password = password;
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
         }
     }];
}

+ (void)loginAsUsername:(NSString *)username password:(NSString *)password
             onComplete:(void(^)(BOOL))completeBlock {
    int userID = [ServerManager getUserIDFromUsername:username password:password];
    if (userID != kURGuestUserID) {
        GlobalStorage *gs = [GlobalStorage sharedInstance];
        [gs switchActiveUser:userID onComplete:^{
            UserData *ud = [[GlobalStorage sharedInstance] activeUserData];
            ud.username = username;
            ud.password = password;
            completeBlock(YES);
        }];
    } else {
        completeBlock(NO);
    }
}

+ (void)logout:(void(^)(void))completeBlock; {
    GlobalStorage *gs = [GlobalStorage sharedInstance];
    [gs switchActiveUser:kURGuestUserID onComplete:^{
        completeBlock();
    }];
}


@end
