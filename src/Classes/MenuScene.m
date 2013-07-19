//
//  MenuScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "MenuScene.h"

#import "Game.h"
#import "LoginScene.h"
#import "RaceScene.h"
#import "ServerManager.h"
#import "Charset.h"

#define BTN_Y_OFFSET 200

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
        banner.autoScale = YES;
        banner.fontSize = 100;
        banner.fontName = @"Chalkduster";
        [self addChild:banner];
        
        // Create buttons
        SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big.png"];
        _buttonList = @[@"English", @"Digits", @"Thai", @"English + Digits", @"Logout"];
        for (int i=0; i < [_buttonList count]; i++) {
            SPButton *button = [SPButton buttonWithUpState:buttonTexture text:_buttonList[i]];
            button.scaleX = 1.2;
            button.scaleY = 1.2;
            button.pivotX = button.width / 2;
            button.pivotY = button.height / 2;
            button.x = gameWidth / 2;
            button.y = BTN_Y_OFFSET + i * (button.height + 10);
            button.name = button.text;
            [button addEventListener:@selector(buttonTriggered:)
                            atObject:self
                             forType:SP_EVENT_TYPE_TRIGGERED];
            [self addChild:button];
        }
        
        // Info bg
        SPQuad *infobg = [SPQuad quadWithWidth:gameWidth height:100];
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
                
                // Update and notify user
                if ([updatedLabels count] > 0) {
                    ud.protosets = protosets;
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
                  best_score: %f\n",
                  ud.userID, ud.username, [ud.protosets count], [ud bestScore]];
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
    if (![button.name isEqualToString:@"Logout"]) {
        GlobalStorage *gs = [GlobalStorage sharedInstance];
        UserData *ud = [gs activeUserData];
        NSArray *prototypes;
        
        // English
        if ([button.name isEqualToString:@"English"]) {
            Charset *cs = [[gs charsets] objectAtIndex:0];
            NSMutableArray *allCharacters = [[NSMutableArray alloc] init];
            [allCharacters addObjectsFromArray:[cs characters]];
            // Set active characters
            [ud setActiveCharacters:allCharacters];
            prototypes = [ud prototypesWithLabels:allCharacters];
        } else if ([button.name isEqualToString:@"Digits"]){
            // Digits
            Charset *cs = [[gs charsets] objectAtIndex:4];
            NSMutableArray *allCharacters = [[NSMutableArray alloc] init];
            [allCharacters addObjectsFromArray:[cs characters]];
            // Set active characters
            [ud setActiveCharacters:allCharacters];
            prototypes = [ud prototypesWithLabels:allCharacters];
        } else if ([button.name isEqualToString:@"Thai"]) {
            Charset *cs = [[gs charsets] objectAtIndex:1];
            NSMutableArray *allCharacters = [[NSMutableArray alloc] init];
            [allCharacters addObjectsFromArray:[cs characters]];
            // Set active characters
            [ud setActiveCharacters:allCharacters];
            prototypes = [ud prototypesWithLabels:allCharacters];
        } else if ([button.name isEqualToString:@"English + Digits"]) {
            Charset *cs_english = [[gs charsets] objectAtIndex:0];
            Charset *cs_digits = [[gs charsets] objectAtIndex:4];
            
            NSMutableArray *allCharacters = [[NSMutableArray alloc] init];
            [allCharacters addObjectsFromArray:[cs_english characters]];
            [allCharacters addObjectsFromArray:[cs_digits characters]];
            
            // Set active characters
            [ud setActiveCharacters:allCharacters];
            prototypes = [ud prototypesWithLabels:allCharacters];
        }
        
        RaceScene *race = [[RaceScene alloc] initWithPrototypes:prototypes];
        [race addEventListenerForType:SP_EVENT_TYPE_REMOVED_FROM_STAGE
                                block:^(id event) {
                                    [self updateInfo];
                                }];
        [self addChild:race];
    } else {
        [[GlobalStorage sharedInstance] switchActiveUser:kURGuestUserID onComplete:^{
            if ([[GlobalStorage sharedInstance] activeUserID] == kURGuestUserID) {
                [self showLoginScene];
            }
        }];
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
}

@end
