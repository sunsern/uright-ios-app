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
#import "InstructionScene.h"

#define RACE_MODE_ID 3
#define EARLY_STOP_MODE_ID 7

@implementation MenuScene {
    double _lastAnnoucement;
    InfoPanel *_infoPanel;
    SPSprite *_mainRaces;
    SPSprite *_advancedRaces;
    NSArray *_advancedRaceLabels;
    BOOL _justLoggedIn;
}

- (id)init
{
    self = [super init];
    if (self) {
        int gameWidth = Sparrow.stage.width;
        int gameHeight = Sparrow.stage.height;
        int y_offset = 0;
        if (gameHeight > 480) {
            y_offset = 20;
        }
        
        // Background
        SPImage *background = [SPImage imageWithContentsOfFile:@"background.jpg"];
        [self addChild:background];
        
        // Logo
        SPTextField *logo = [SPTextField textFieldWithText:@"uRight"];
        logo.width = gameWidth-40;
        logo.height = 120;
        logo.pivotX = logo.width / 2;
        logo.x = gameWidth / 2;
        logo.y = y_offset + 15;
        logo.fontSize = 80;
        logo.fontName = @"Chalkduster";
        logo.autoScale = YES;
        [self addChild:logo];
        
        // Main races
        _mainRaces = [[SPSprite alloc] init];
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
            [_mainRaces addChild:button];
        }
        _mainRaces.y = logo.y + logo.height + 50;
        [self addChild:_mainRaces];
        
        // Advanced races
        _advancedRaces = [[SPSprite alloc] init];
        SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big-borderless.png"];
        _advancedRaceLabels = @[@{@"name" : @"English U&L + Digits", @"req" : @(3)},
                                @{@"name" : @"Hebrew", @"req" : @(4)},
                                @{@"name" : @"Thai", @"req" : @(4)},
                                @{@"name" : @"Japanese", @"req" : @(4)},
                                @{@"name" : @"Speedy English", @"req" : @(5)},
                                @{@"name" : @"Your custom race", @"req" : @(6)},
                                @{@"name" : @"Design your own", @"req" : @(6)}];
        for (int i=0; i < [_advancedRaceLabels count] + 1; i++) {
            SPButton *button = [SPButton buttonWithUpState:buttonTexture];
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
            button.fontSize = 9;
            button.scaleX = 1.2;
            button.scaleY = 1.2;
            
            if (i < [_advancedRaceLabels count]) {
                button.text = [NSString stringWithFormat:@"%@\n[Lv.%@]",
                               _advancedRaceLabels[i][@"name"],
                               _advancedRaceLabels[i][@"req"]];
                button.name = _advancedRaceLabels[i][@"name"];
            }
            else {
                button.text = @"Back";
                button.name = @"Back";
                button.fontSize = 12;
            }
            
            [button addEventListener:@selector(buttonTriggered:)
                            atObject:self
                             forType:SP_EVENT_TYPE_TRIGGERED];
            [_advancedRaces addChild:button];
        }
        
        _advancedRaces.y = logo.y + logo.height + 60;
        _advancedRaces.visible = NO;
        [self addChild:_advancedRaces];
        
        
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
        

        // Help button
        SPTexture *helpTexture = [SPTexture textureWithContentsOfFile:@"help_black.png"];
        SPButton *helpButton = [SPButton buttonWithUpState:helpTexture];
        helpButton.pivotX = helpButton.width;
        helpButton.x = gameWidth;
        helpButton.y = 0;
        helpButton.scaleX = 0.50;
        helpButton.scaleY = 0.50;
        [self addChild:helpButton];
        [helpButton addEventListener:@selector(showHelp) atObject:self
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
        _justLoggedIn = NO;
        
        // Hide until logged in
        self.visible = NO;
    }
    return self;
}


- (void)dealloc {
    [self removeEventListenersAtObject:self forType:SP_EVENT_TYPE_ADDED_TO_STAGE];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}



- (void)showHelp {
    _mainRaces.visible = YES;
    _advancedRaces.visible = NO;
    
    if (Sparrow.stage.height > 480) {
        InstructionScene *instruction = [[InstructionScene alloc]
                                         initWithImageName:@"menu-instruction-568.png"];
        [self addChild:instruction];
    }
    else {
        InstructionScene *instruction = [[InstructionScene alloc]
                                         initWithImageName:@"menu-instruction.png"];
        [self addChild:instruction];
    }
}

- (void)updateInfo {
    Userdata *ud = [[GlobalStorage sharedInstance] activeUserdata];

    [_infoPanel updatePanel];
    
    [self lockRaces];
    
    // User instruction
    if (ud.experience == 0.0 && _justLoggedIn) {
        [self showHelp];
    }
    else {
        // Check for annoucement from server.
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
    }
    
    // Refresh experience and level
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSDictionary *userStats = [ServerManager fetchUserStats:ud.userID];
        if (userStats) {
            dispatch_async(dispatch_get_main_queue(), ^{
                int old_level = ud.level;
                
                ud.level = [userStats[@"level"] intValue];
                ud.experience = [userStats[@"experience"] floatValue];
                ud.nextLevelExp = [userStats[@"next_level_exp"] floatValue];
                ud.thisLevelExp = [userStats[@"this_level_exp"] floatValue];
                ud.bestBps = [userStats[@"best_bps"] floatValue];
                ud.scores = [[NSArray alloc] initWithArray:userStats[@"recent_bps"]];
                [_infoPanel updatePanel];
                [self lockRaces];
                
                // Level up!
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
    
    _justLoggedIn = NO;
}

- (void)lockRaces {
    Userdata *ud = [[GlobalStorage sharedInstance] activeUserdata];
    for (int i=0; i < [_advancedRaceLabels count]; i++) {
        NSDictionary *info = _advancedRaceLabels[i];
        SPButton *button = (SPButton *)[_advancedRaces childByName:info[@"name"]];
        if (button) {
            if (ud.level < [info[@"req"] intValue]) {
                button.enabled = NO;
            }
            else {
                button.enabled = YES;
            }
        }
    }
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
        _advancedRaces.visible = YES;
        _mainRaces.visible = NO;
    }
    else if ([button.name isEqualToString:@"Back"]) {
        _advancedRaces.visible = NO;
        _mainRaces.visible = YES;
    }
    else if ([button.name isEqualToString:@"Design your own"]) {
        EditCustomScene *crs = [[EditCustomScene alloc] init];
        [self addChild:crs];
    }
    else if ([button.name isEqualToString:@"Speedy English"]) {
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
        } else if ([button.name isEqualToString:@"English U&L + Digits"]) {
            Charset *cs_english = [gs charsetByID:1];
            Charset *cs_digits = [gs charsetByID:12];
            Charset *cs_punc = [gs charsetByID:14];
            Charset *cs_upper = [gs charsetByID:13];
            [allCharacters addObjectsFromArray:[cs_english characters]];
            [allCharacters addObjectsFromArray:[cs_digits characters]];
            [allCharacters addObjectsFromArray:[cs_upper characters]];
            [allCharacters addObjectsFromArray:[cs_punc characters]];
        } else if ([button.name isEqualToString:@"Your custom race"]) {
            Userdata *ud = [gs activeUserdata];
            Charset *cs = ud.customCharset;
            [allCharacters addObjectsFromArray:[cs characters]];
            
            if ([allCharacters count] == 0) {
                GRAlertView *alert = [[GRAlertView alloc]
                                      initWithTitle:@"Race Empty"
                                      message:@"Use \"Design your own\" to add characters."
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
                alert.style = GRAlertStyleAlert;
                alert.animation = GRAlertAnimationLines;
                [alert show];
            }
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
    GlobalStorage *gs = [GlobalStorage sharedInstance];
    if ([PFUser currentUser] == nil ||
        [gs activeUserID] == UR_GUEST_ID ||
        [gs activeUserdata].username == nil ||
        [[gs activeUserdata].username isEqualToString:@"unknown"]) {
      
        [PFUser logOut];
        [Sparrow.juggler delayInvocationByTime:0.05 block:^{
            [self showLoginScene];
            // Make menu visible in the back
            self.visible = YES;
        }];
        
    } else {
        // Make menu visible
        self.visible = YES;
        
        [self updateInfo];
    }
}

- (void)showLoginScene {
    PFLogInViewController *login = [[LoginViewController alloc] init];
    [Sparrow.currentController presentModalViewController:login animated:NO];
}

- (void)logInCompleted:(NSNotification *)notification {
    _justLoggedIn = YES;
    [self updateInfo];
}

@end
