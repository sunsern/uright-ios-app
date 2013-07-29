//
//  MenuScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//
#import <Parse/Parse.h>

#import "MenuScene.h"

#import "AccountManager.h"
#import "Charset.h"
#import "EditCustomScene.h"
#import "GlobalStorage.h"
#import "LoginViewController.h"
#import "MBProgressHUD.h"
#import "RaceScene.h"
#import "ScoreViewController.h"
#import "ServerManager.h"
#import "Userdata.h"
#import "InfoPanel.h"
#import "GRAlertView.h"

#define RACE_MODE_ID 3
#define EARLY_STOP_MODE_ID 7

@implementation MenuScene {
    double _lastAnnoucement;
    InfoPanel *_infoPanel;
    SPSprite *_page1;
    SPSprite *_page2;
}

- (id)init
{
    self = [super init];
    if (self) {
        int gameWidth = Sparrow.stage.width;
        int gameHeight = Sparrow.stage.height;
        int y_offset = 0;
        if (gameHeight > 480) {
            y_offset = 40;
        }
        
        // Background
        SPImage *background = [SPImage imageWithContentsOfFile:@"background.jpg"];
        [self addChild:background];
        
        // Logo
        SPTextField *logo = [SPTextField textFieldWithText:@"uRight"];
        logo.width = gameWidth-40;
        logo.height = 100;
        logo.pivotX = logo.width / 2;
        logo.x = gameWidth / 2;
        logo.y = 10;
        logo.fontSize = 80;
        logo.fontName = @"Chalkduster";
        logo.autoScale = YES;
        [self addChild:logo];
        
        // Page 1
        _page1 = [[SPSprite alloc] init];
        SPTexture *bigButtonTexture = [SPTexture textureWithContentsOfFile:@"blank-without-border.png"];
        NSArray *buttonPage1 = @[@"English", @"Digits", @"More..."];
        for (int i=0; i < [buttonPage1 count]; i++) {
            SPButton *button = [SPButton buttonWithUpState:bigButtonTexture text:buttonPage1[i]];
            button.pivotX = button.width / 2;
            button.pivotY = button.height / 2;
            button.x = gameWidth / 2;
            button.y = i * (button.height + 10);
            button.name = button.text;
            button.fontName = @"Chalkduster";
            button.fontSize = 20;
            button.scaleX = 1.0;
            [button addEventListener:@selector(buttonTriggered:)
                            atObject:self
                             forType:SP_EVENT_TYPE_TRIGGERED];
            [_page1 addChild:button];
        }
        _page1.y = logo.y + logo.height + y_offset + 60;
        [self addChild:_page1];
        
        // Create buttons
        _page2 = [[SPSprite alloc] init];
        SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big-borderless.png"];
        NSArray *buttonPage2 = @[@"Thai", @"Hebrew",
                                 @"Japanese", @"Full",
                                 @"English-early-stop", @"Custom",
                                 @"Edit Custom", @"Back"];
        for (int i=0; i < [buttonPage2 count]; i++) {
            SPButton *button = [SPButton buttonWithUpState:buttonTexture text:buttonPage2[i]];
            button.pivotX = button.width / 2;
            button.pivotY = button.height / 2;
            if (i % 2 == 0) {
                button.x = gameWidth / 4;
                button.y = (i/2) * (button.height + 10);
            } else {
                button.x = 3 * gameWidth / 4;
                button.y = (i/2) * (button.height + 10);
            }
            button.fontName = @"Chalkduster";
            button.fontSize = 12;
            button.name = button.text;
            button.scaleX = 1.2;
            button.scaleY = 1.2;
            if (![button.text isEqualToString:@"Back"]) {
                button.enabled = YES;
            }
            [button addEventListener:@selector(buttonTriggered:)
                            atObject:self
                             forType:SP_EVENT_TYPE_TRIGGERED];
            [_page2 addChild:button];
        }
        _page2.y = logo.y + logo.height + y_offset + 60;
        _page2.visible = NO;
        [self addChild:_page2];
        
        
        // Info panel
        SPQuad *infobg = [SPQuad quadWithWidth:gameWidth height:60];
        infobg.y = gameHeight - infobg.height;
        infobg.color = 0x000000;
        infobg.alpha = 0.5;
        [self addChild:infobg];
        
        _infoPanel = [[InfoPanel alloc] initWithWidth:gameWidth - 95 height:infobg.height];
        _infoPanel.x = 42;
        _infoPanel.y = infobg.y;
        [self addChild:_infoPanel];
    
        [self addEventListener:@selector(addedToStage:)
                      atObject:self
                       forType:SP_EVENT_TYPE_ADDED_TO_STAGE];
        
        
        // score button
        SPTexture *scoreTexture = [SPTexture textureWithContentsOfFile:@"graph.png"];
        SPButton *scoreButton = [SPButton buttonWithUpState:scoreTexture];
        scoreButton.pivotX = scoreButton.width;
        scoreButton.pivotY = 0;
        scoreButton.x = gameWidth - 8;
        scoreButton.y = infobg.y + (infobg.height - scoreButton.height) / 2;
        scoreButton.scaleX = 1.0;
        scoreButton.scaleY = 1.0;
        [self addChild:scoreButton];
        [scoreButton addEventListener:@selector(score) atObject:self
                              forType:SP_EVENT_TYPE_TRIGGERED];
        
        
        // Log out button
        SPTexture *logoutTexture = [SPTexture textureWithContentsOfFile:@"switch-user.png"];
        SPButton *logoutButton = [SPButton buttonWithUpState:logoutTexture];
        logoutButton.x = 0;
        logoutButton.y = infobg.y + 5;
        logoutButton.scaleX = 0.75;
        logoutButton.scaleY = 0.75;
        [self addChild:logoutButton];
        [logoutButton addEventListener:@selector(logout) atObject:self
                               forType:SP_EVENT_TYPE_TRIGGERED];
        

        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(logInCompleted:)
         name:NS_NOTIFICATION_LOGGED_IN
         object:nil];
        
        [[NSNotificationCenter defaultCenter]
         addObserver:self
         selector:@selector(updateInfo)
         name:UIApplicationWillEnterForegroundNotification
         object:nil];
        
        _lastAnnoucement = 0;
    }
    return self;
}


- (void)dealloc {
    [self removeEventListenersAtObject:self forType:SP_EVENT_TYPE_ADDED_TO_STAGE];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)updateInfo {
    Userdata *ud = [[GlobalStorage sharedInstance] activeUserdata];
    
    [_infoPanel updatePanel];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSDictionary *annoucement = [ServerManager announcement];
        dispatch_async(dispatch_get_main_queue(), ^{
            double timestamp = [annoucement[@"timestamp"] doubleValue];
            if (timestamp > _lastAnnoucement) {
                NSString *text = annoucement[@"annoucement"];
                _lastAnnoucement = timestamp;
                GRAlertView *alert = [[GRAlertView alloc]
                                      initWithTitle:@"Annoucement"
                                      message:text
                                      delegate:nil
                                      cancelButtonTitle:@"Close"
                                      otherButtonTitles:nil];
                alert.style = GRAlertStyleInfo;
                alert.animation = GRAlertAnimationLines;
                [alert show];
            }
        });
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSDictionary *userStats = [ServerManager fetchUserStats:ud.userID];
        if (userStats) {
            dispatch_async(dispatch_get_main_queue(), ^{
                int old_level = ud.level;
                
                ud.level = [userStats[@"level"] intValue];
                ud.experience = [userStats[@"experience"] floatValue];
                ud.nextLevelExp = [userStats[@"next_level_exp"] floatValue];
                ud.bestBps = [userStats[@"best_bps"] floatValue];
                ud.scores = [[NSArray alloc] initWithArray:userStats[@"recent_bps"]];
                [_infoPanel updatePanel];
                
                if (ud.level > old_level) {
                    NSString *text = [NSString stringWithFormat:@"You are now level %d.",
                                      ud.level];
                    GRAlertView *alert = [[GRAlertView alloc]
                                          initWithTitle:@"Level up!"
                                          message:text
                                          delegate:nil
                                          cancelButtonTitle:@"Close"
                                          otherButtonTitles:nil];
                    alert.style = GRAlertStyleInfo;
                    alert.animation = GRAlertAnimationLines;
                    [alert setImage:@"up.png"];
                    [alert show];
                    [Media playSound:@"kids_cheer.caf"];
                }
            });
        }
    });
   
}

- (void)logout {
    UIView *view = Sparrow.currentController.view;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Logging out...";
    [AccountManager logout:^ {
        [PFUser logOut];
        [hud hide:YES];
        [self showLoginScene];
        
        // reset annoucement
        _lastAnnoucement = 0;
    }];
}


- (void)score {
    ScoreViewController *scoreVC = [[ScoreViewController alloc] init];
    [Sparrow.currentController presentModalViewController:scoreVC animated:YES];
}


- (void)buttonTriggered:(SPEvent *)event {
    SPButton *button = (SPButton *)event.target;
    
    if ([button.name isEqualToString:@"More..."]) {
        _page2.visible = YES;
        _page1.visible = NO;
    }
    else if ([button.name isEqualToString:@"Back"]) {
        _page2.visible = NO;
        _page1.visible = YES;
    }
    else if ([button.name isEqualToString:@"Edit Custom"]) {
        EditCustomScene *crs = [[EditCustomScene alloc] init];
        [self addChild:crs];
    }
    else if ([button.name isEqualToString:@"English-early-stop"]) {
        NSMutableArray *allCharacters = [[NSMutableArray alloc] init];
     
        // English
        Charset *cs = [[GlobalStorage sharedInstance] charsetByID:1];
        [allCharacters addObjectsFromArray:[cs characters]];
        
        RaceScene *race = [[RaceScene alloc] initWithCharacters:allCharacters
                                                 classifierMode:BFClassifierModeEarlyPenup
                                                         modeID:EARLY_STOP_MODE_ID];
        
        [race addEventListenerForType:SP_EVENT_TYPE_REMOVED_FROM_STAGE
                                block:^(id event) {
                                    [self updateInfo];
                                }];
        [self addChild:race];
    }
    else {
        GlobalStorage *gs = [GlobalStorage sharedInstance];
        NSMutableArray *allCharacters = [[NSMutableArray alloc] init];
        
        if ([button.name isEqualToString:@"English"]) {
            Charset *cs = [gs charsetByID:1];
            [allCharacters addObjectsFromArray:[cs characters]];
        } else if ([button.name isEqualToString:@"Digits"]){
            Charset *cs = [gs charsetByID:12];
            [allCharacters addObjectsFromArray:[cs characters]];
        } else if ([button.name isEqualToString:@"Thai"]) {
            Charset *cs = [gs charsetByID:2];;
            [allCharacters addObjectsFromArray:[cs characters]];
        } else if ([button.name isEqualToString:@"Hebrew"]) {
            Charset *cs = [gs charsetByID:3];;
            [allCharacters addObjectsFromArray:[cs characters]];
        } else if ([button.name isEqualToString:@"Japanese"]) {
            Charset *cs = [gs charsetByID:15];;
            [allCharacters addObjectsFromArray:[cs characters]];
        } else if ([button.name isEqualToString:@"Full"]) {
            Charset *cs_english = [gs charsetByID:1];
            Charset *cs_digits = [gs charsetByID:12];
            Charset *cs_punc = [gs charsetByID:14];
            Charset *cs_upper = [gs charsetByID:13];
            [allCharacters addObjectsFromArray:[cs_english characters]];
            [allCharacters addObjectsFromArray:[cs_digits characters]];
            [allCharacters addObjectsFromArray:[cs_upper characters]];
            [allCharacters addObjectsFromArray:[cs_punc characters]];
        } else if ([button.name isEqualToString:@"Custom"]) {
            Userdata *ud = [gs activeUserdata];
            Charset *cs = ud.customCharset;
            [allCharacters addObjectsFromArray:[cs characters]];
        }
        
        if ([allCharacters count] > 0) {
            RaceScene *race = [[RaceScene alloc] initWithCharacters:allCharacters
                                                     classifierMode:BFClassifierModeBatch
                                                             modeID:RACE_MODE_ID];
            
            [race addEventListenerForType:SP_EVENT_TYPE_REMOVED_FROM_STAGE
                                    block:^(id event) {
                                        [self updateInfo];
                                    }];
            [self addChild:race];
        }
    }
}

- (void)addedToStage:(SPEvent *)event {
    if ([PFUser currentUser] == nil ||
        [[GlobalStorage sharedInstance] activeUserID] == UR_GUEST_ID) {
      
        [PFUser logOut];
        [Sparrow.juggler delayInvocationByTime:0.05 block:^{
            [self showLoginScene];
        }];
        
    } else {
        [self updateInfo];
    }
}

- (void)showLoginScene {
    PFLogInViewController *login = [[LoginViewController alloc] init];
    [Sparrow.currentController presentModalViewController:login animated:YES];
}

- (void)logInCompleted:(NSNotification *)notification {
    [self updateInfo];
}

@end
