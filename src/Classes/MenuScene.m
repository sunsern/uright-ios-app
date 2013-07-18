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

@implementation MenuScene {
    LoginScene *_login;
    SPTextField *_info;
    NSArray *_buttonList;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setupScene];
    }
    return self;
}


- (void)updateInfo {
    UserData *ud = [[GlobalStorage sharedInstance] activeUserData];
    _info.text = [NSString stringWithFormat:@"User id: %d \
                  Username: %@\nprotosets: %d \
                  high score: %f",
                  ud.userID, ud.username, [ud.protosets count], [ud bestScore]];
    
}


- (void)setupScene {
    int gameWidth = Sparrow.stage.width;
    //int gameHeight = Sparrow.stage.height;
    
    // Background
    //SPQuad *background = [SPQuad quadWithWidth:gameWidth height:gameHeight color:0xffffff];
    SPImage *background = [SPImage imageWithContentsOfFile:@"background.jpg"];
    [self addChild:background];
    
    // Create buttons
    SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big.png"];
    _buttonList = @[@"English", @"Digits", @"Thai", @"Logout"];
    for (int i=0; i < [_buttonList count]; i+=2) {
        SPButton *button_l = [SPButton buttonWithUpState:buttonTexture text:_buttonList[i]];
        button_l.pivotX = button_l.width / 2;
        button_l.pivotY = button_l.height / 2;
        button_l.x = gameWidth / 4;
        button_l.y = 250 + i * (button_l.height + 5);
        button_l.name = button_l.text;
        [button_l addEventListener:@selector(buttonTriggered:)
                        atObject:self
                         forType:SP_EVENT_TYPE_TRIGGERED];
        [self addChild:button_l];
        
        if (i+1 < [_buttonList count]) {
            SPButton *button_r = [SPButton buttonWithUpState:buttonTexture text:_buttonList[i+1]];
            button_r.pivotX = button_r.width / 2;
            button_r.pivotY = button_r.height / 2;
            button_r.x = gameWidth*3 / 4;
            button_r.y = 250 + i * (button_r.height + 5);
            button_r.name = button_r.text;
            [button_r addEventListener:@selector(buttonTriggered:)
                              atObject:self
                               forType:SP_EVENT_TYPE_TRIGGERED];
            [self addChild:button_r];
        }
    }

    _info = [[SPTextField alloc] initWithWidth:gameWidth-20 height:100];
    _info.pivotX = _info.width / 2;
    _info.x = gameWidth / 2;
    _info.color = 0x000000;
    [self addChild:_info];
    [self updateInfo];

    [self addEventListener:@selector(onAddedToStage:)
                  atObject:self
                   forType:SP_EVENT_TYPE_ADDED_TO_STAGE];

}

- (void)dealloc {
    [self removeEventListenersAtObject:self forType:SP_EVENT_TYPE_ADDED_TO_STAGE];
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
            // Set active characters
            [ud setActiveCharacters:[[NSMutableArray alloc]
                                     initWithArray:[cs characters]]];
            prototypes = [ud prototypesWithLabels:[cs characters]];
        } else if ([button.name isEqualToString:@"Digits"]){
            // Digits
            Charset *cs = [[gs charsets] objectAtIndex:4];
            // Set active characters
            [ud setActiveCharacters:[[NSMutableArray alloc]
                                     initWithArray:[cs characters]]];
            prototypes = [ud prototypesWithLabels:[cs characters]];
        } else if ([button.name isEqualToString:@"Thai"]) {
            Charset *cs = [[gs charsets] objectAtIndex:1];
            // Set active characters
            [ud setActiveCharacters:[[NSMutableArray alloc]
                                     initWithArray:[cs characters]]];
            prototypes = [ud prototypesWithLabels:[cs characters]];
        }
        
        RaceScene *race = [[RaceScene alloc] initWithPrototypes:prototypes];
        [race addEventListenerForType:SP_EVENT_TYPE_REMOVED_FROM_STAGE
                                block:^(id event) {
                                    [self updateInfo];
                                }];
        [(Game *)Sparrow.root showScene:race];
    } else {
        [[GlobalStorage sharedInstance] switchActiveUser:kURGuestUserID onComplete:^{
            if ([[GlobalStorage sharedInstance] activeUserID] == kURGuestUserID) {
                LoginScene *login = [[LoginScene alloc] init];
                login.y = 30;
                [login addEventListenerForType:SP_EVENT_TYPE_REMOVED_FROM_STAGE
                                         block:^(id event) {
                                             [self updateInfo];
                                         }];
                [self addChild:login];
            }
        }];
    }
    [self updateInfo];
}

- (void)onAddedToStage:(SPEvent *)event {
    if ([[GlobalStorage sharedInstance] activeUserID] == kURGuestUserID) {
        LoginScene *login = [[LoginScene alloc] init];
        login.y = 30;
        [login addEventListenerForType:SP_EVENT_TYPE_REMOVED_FROM_STAGE
                                 block:^(id event) {
                                     [self updateInfo];
                                 }];
        [self addChild:login];
    }
}

@end
