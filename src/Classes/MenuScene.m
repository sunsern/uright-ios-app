//
//  MenuScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "MenuScene.h"

#import "Game.h"
#import "ServerManager.h"
#import "Charset.h"

#import "LoginScene.h"
#import "RaceScene.h"
#import "EditCustomScene.h"

@implementation MenuScene {
    LoginScene *_login;
    SPTextField *_info;
    NSArray *_buttonList;
    BOOL _fetchingProtosets;
}

- (id)init
{
    self = [super init];
    if (self) {
        int gameWidth = Sparrow.stage.width;
        int gameHeight = Sparrow.stage.height;
        
        // Background
        //SPQuad *background = [SPQuad quadWithWidth:gameWidth height:gameHeight color:0xffffff];
        SPImage *background = [SPImage imageWithContentsOfFile:@"background.jpg"];
        [self addChild:background];
        
        // Banner
        SPTextField *banner = [SPTextField textFieldWithText:@"uRight3"];
        banner.width = gameWidth-40;
        banner.height = 100;
        banner.pivotX = banner.width / 2;
        banner.x = gameWidth / 2;
        banner.y = 10;
        banner.fontSize = 100;
        banner.fontName = @"Chalkduster";
        banner.autoScale = YES;
        [self addChild:banner];
        
        // button box
        SPSprite *buttons = [[SPSprite alloc] init];
        [self addChild:buttons];
        
        // Create buttons
        SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big.png"];
        _buttonList = @[@"English", @"Digits",
                        @"Thai", @"English + Digits",
                        @"Hebrew", @"Japanese",
                        @"Full", @"Custom",
                        @"Edit Custom", @"Logout"];
        for (int i=0; i < [_buttonList count]; i++) {
            SPButton *button = [SPButton buttonWithUpState:buttonTexture text:_buttonList[i]];
            button.pivotX = button.width / 2;
            button.pivotY = button.height / 2;
            if (i % 2 == 0) {
                button.x = gameWidth / 4;
                button.y = (i/2) * (button.height + 10);
            } else {
                button.x = 3 * gameWidth / 4;
                button.y = (i/2) * (button.height + 10);
            }
            button.name = button.text;
            button.scaleX = 1.1;
            button.scaleY = 1.1;
            [button addEventListener:@selector(buttonTriggered:)
                            atObject:self
                             forType:SP_EVENT_TYPE_TRIGGERED];
            [buttons addChild:button];
        }
        // Center verti
        buttons.y = 20 + (gameHeight - buttons.height) / 2;
        
        // Info panel
        SPQuad *infobg = [SPQuad quadWithWidth:gameWidth height:80];
        infobg.y = gameHeight - infobg.height;
        infobg.color = 0x000000;
        infobg.alpha = 0.5;
        [self addChild:infobg];
        
        _info = [SPTextField textFieldWithWidth:gameWidth height:infobg.height text:@""];
        _info.y = gameHeight - _info.height;
        _info.fontName = @"Symbol";
        _info.color = 0xffffff;
        _info.autoScale = YES;
        [self addChild:_info];
        
        [self addEventListener:@selector(addedToStage:)
                      atObject:self
                       forType:SP_EVENT_TYPE_ADDED_TO_STAGE];
        
        _fetchingProtosets = NO;
    }
    return self;
}


- (void)dealloc {
    [self removeEventListenersAtObject:self forType:SP_EVENT_TYPE_ADDED_TO_STAGE];
}


- (void)updateInfo {
    UserData *ud = [[GlobalStorage sharedInstance] activeUserData];
    
    if (!_fetchingProtosets) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            _fetchingProtosets = YES;
            NSDictionary *protosets = [ServerManager fetchProtosets:ud.userID];
            if (protosets) {
                NSMutableArray *updatedLabels = [[NSMutableArray alloc] init];
                for (id key in ud.protosets) {
                    Protoset *old_ps = ud.protosets[key];
                    Protoset *new_ps = protosets[key];
                    if (new_ps.protosetID > old_ps.protosetID) {
                        [updatedLabels addObject:key];
                    }
                }
                for (id key in protosets) {
                    if (ud.protosets[key] == nil) {
                        [updatedLabels addObject:key];
                    }
                }
                    
                // Update and notify user
                if ([updatedLabels count] > 0) {
                    [ud setProtosets:protosets];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self protosetUpdated:updatedLabels];
                    });
                }
            }
            _fetchingProtosets = NO;
        });
    }
    _info.text = [NSString stringWithFormat:
                  @"[Debug info]\n"
                  "user_id: %d \
                  username: %@\n"
                  "n_protosets: %d \
                  best_score: %f\n"
                  "version: %@ \
                  build: %@\n",
                  ud.userID, ud.username, [ud.protosets count], [ud bestScore],
                  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
}


- (void)protosetUpdated:(NSArray *)labels {
    NSMutableString *list = [[NSMutableString alloc] init];
    [list appendFormat:@"[%@",labels[0]];
    for (int i=1; i < [labels count]; i++) {
        [list appendFormat:@", %@",labels[i]];
    }
    [list appendFormat:@"]"];
    NSString *mesg = [NSString
                      stringWithFormat:@"New prototypes for %@ were added to your collection", list];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"New prototypes"
                                                    message:mesg
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}


- (void)buttonTriggered:(SPEvent *)event {
    SPButton *button = (SPButton *)event.target;
    if ([button.name isEqualToString:@"Logout"]) {
        [[GlobalStorage sharedInstance] switchActiveUser:kURGuestUserID onComplete:^{
            if ([[GlobalStorage sharedInstance] activeUserID] == kURGuestUserID) {
                [self showLoginScene];
            }
        }];
    } else if ([button.name isEqualToString:@"Edit Custom"]) {
        EditCustomScene *crs = [[EditCustomScene alloc] init];
        [self addChild:crs];
    } else {
        GlobalStorage *gs = [GlobalStorage sharedInstance];
        UserData *ud = [gs activeUserData];
        NSArray *prototypes;
        NSMutableArray *allCharacters = [[NSMutableArray alloc] init];
        
        if ([button.name isEqualToString:@"English"]) {
            Charset *cs = [gs charsetByID:1];
            [allCharacters addObjectsFromArray:[cs characters]];
        } else if ([button.name isEqualToString:@"Digits"]){
            Charset *cs = [gs charsetByID:12];
            NSMutableArray *allCharacters = [[NSMutableArray alloc] init];
            [allCharacters addObjectsFromArray:[cs characters]];
        } else if ([button.name isEqualToString:@"Thai"]) {
            Charset *cs = [gs charsetByID:2];;
            NSMutableArray *allCharacters = [[NSMutableArray alloc] init];
            [allCharacters addObjectsFromArray:[cs characters]];
        } else if ([button.name isEqualToString:@"Hebrew"]) {
            Charset *cs = [gs charsetByID:3];;
            NSMutableArray *allCharacters = [[NSMutableArray alloc] init];
            [allCharacters addObjectsFromArray:[cs characters]];
        } else if ([button.name isEqualToString:@"Japanese"]) {
            Charset *cs = [gs charsetByID:15];;
            NSMutableArray *allCharacters = [[NSMutableArray alloc] init];
            [allCharacters addObjectsFromArray:[cs characters]];
        } else if ([button.name isEqualToString:@"English + Digits"]) {
            Charset *cs_english = [gs charsetByID:1];
            Charset *cs_digits = [gs charsetByID:12];
            NSMutableArray *allCharacters = [[NSMutableArray alloc] init];
            [allCharacters addObjectsFromArray:[cs_english characters]];
            [allCharacters addObjectsFromArray:[cs_digits characters]];
        } else if ([button.name isEqualToString:@"Full"]) {
            Charset *cs_english = [gs charsetByID:1];
            Charset *cs_digits = [gs charsetByID:12];
            Charset *cs_punc = [gs charsetByID:14];
            Charset *cs_upper = [gs charsetByID:13];
            NSMutableArray *allCharacters = [[NSMutableArray alloc] init];
            [allCharacters addObjectsFromArray:[cs_english characters]];
            [allCharacters addObjectsFromArray:[cs_digits characters]];
            [allCharacters addObjectsFromArray:[cs_upper characters]];
            [allCharacters addObjectsFromArray:[cs_punc characters]];
        } else if ([button.name isEqualToString:@"Custom"]) {
            Charset *cs = ud.customCharset;
            NSMutableArray *allCharacters = [[NSMutableArray alloc] init];
            [allCharacters addObjectsFromArray:[cs characters]];
        }
        
        // Set active characters
        [ud setActiveCharacters:allCharacters];
        prototypes = [ud prototypesWithLabels:allCharacters];
        
        RaceScene *race = [[RaceScene alloc] initWithPrototypes:prototypes];
        [race addEventListenerForType:SP_EVENT_TYPE_REMOVED_FROM_STAGE
                                block:^(id event) {
                                    [self updateInfo];
                                }];
        [self addChild:race];
    }
}

- (void)addedToStage:(SPEvent *)event {
    if ([[GlobalStorage sharedInstance] activeUserID] == kURGuestUserID) {
        [self showLoginScene];
    } else {
        [self updateInfo];
    }
}

- (void)showLoginScene {
    LoginScene *login = [[LoginScene alloc] init];
    [login addEventListenerForType:SP_EVENT_TYPE_REMOVED_FROM_STAGE
                             block:^(id event) {
                                 [self updateInfo];
                             }];
    [self addChild:login];
    [Sparrow.juggler delayInvocationByTime:0.01f block:^{
        [login showTextFields];
    }];
}

@end
