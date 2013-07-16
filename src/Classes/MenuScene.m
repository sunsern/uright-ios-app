//
//  MenuScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import <FacebookSDK/FacebookSDK.h>

#import "MenuScene.h"

#import "Game.h"
#import "LoginScene.h"
#import "RaceScene.h"
#import "ServerManager.h"

@implementation MenuScene {
    LoginScene *_login;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setupScene];
    }
    return self;
}


- (void)setupScene {
    int gameWidth = Sparrow.stage.width;
    int gameHeight = Sparrow.stage.height;
    
    // Background
    SPQuad *background = [SPQuad quadWithWidth:gameWidth height:gameHeight color:0xffffff];
    //SPImage *background = [SPImage imageWithContentsOfFile:@"background.jpg"];
    [self addChild:background];
    
    // Create buttons
    SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big.png"];
    NSArray *buttonList = @[@"Race", @"Collect", @"Logout"];
    for (int i=0; i < [buttonList count]; i++) {
        SPButton *button = [SPButton buttonWithUpState:buttonTexture text:buttonList[i]];
        button.pivotX = button.width / 2;
        button.pivotY = button.height / 2;
        button.x = gameWidth / 2;
        button.y = 200 + i * (button.height + 10);
        button.name = button.text;
        [button addEventListener:@selector(buttonTriggered:)
                        atObject:self
                         forType:SP_EVENT_TYPE_TRIGGERED];
        [self addChild:button];
    }

    FBSession *session = [[FBSession alloc] init];
    [FBSession setActiveSession:session];
    
    
    [self addEventListener:@selector(onAddedToStage:)
                  atObject:self
                   forType:SP_EVENT_TYPE_ADDED_TO_STAGE];

}

- (void)dealloc {
    [self removeEventListenersAtObject:self forType:SP_EVENT_TYPE_ADDED_TO_STAGE];
}


- (void)buttonTriggered:(SPEvent *)event {
    SPButton *button = (SPButton *)event.target;
    if ([button.name isEqualToString:@"Race"]) {
        RaceScene *race = [[RaceScene alloc] init];
        [(Game *)Sparrow.root showScene:race];
    } else if ([button.name isEqualToString:@"Collect"]) {
        // pass
    } else if ([button.name isEqualToString:@"Logout"]) {
        NSArray *permissions = @[@"email"];
        
        // Attempt to open the session. If the session is not open, show the user the Facebook login UX
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
             }
             else
             {
                 // Update our game now we've logged in
                 NSLog(@"Success");
                 if (FBSession.activeSession.isOpen) {
                     
                     // Request data
                     [[FBRequest requestForMe] startWithCompletionHandler:
                      ^(FBRequestConnection *connection,
                        NSDictionary <FBGraphUser> *user,
                        NSError *error) {
                          if (!error) {
                              
                              int userID = [ServerManager getUserIdFromUsername:user.username
                                                                       password:user.id];
                              
                              // New user
                              if (userID < 0) {
                                  NSString *username = [NSString stringWithFormat:@"FB_%@",user.username];
                                  userID = [ServerManager createAccountForUsername:username
                                                                          password:user.id
                                                                             email:user[@"email"]
                                                                          fullname:user.name];
                                  
                                  if (userID > 0) {
                                      NSLog(@"Created a new account %d", userID);
                                  }
                              }
                          }
                      }];
                 }
             }
         }];
    } else {
        // pass
    }
}

- (void)onAddedToStage:(SPEvent *)event {
    // pass
}

@end
