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
#import "CollectScene.h"
#import "ServerManager.h"

@implementation MenuScene {
    LoginScene *_login;
    SPTextField *_info;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setupScene];
    }
    return self;
}


- (void)printInfo {
    UserData *us = [[GlobalStorage sharedInstance] activeUser];
    _info.text = [NSString stringWithFormat:@"User id: %d, Lang id: %d, Username: %@",
                  us.userID, us.languageID, us.username];
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

    _info = [[SPTextField alloc] initWithWidth:gameWidth height:100];
    [self addChild:_info];
    [self printInfo];
    
    
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
        CollectScene *collect = [[CollectScene alloc] init];
        [(Game *)Sparrow.root showScene:collect];
    } else if ([button.name isEqualToString:@"Logout"]) {
        // pass
    }
    [self printInfo];
}

- (void)onAddedToStage:(SPEvent *)event {
    if ([[GlobalStorage sharedInstance] activeUserID] == kURGuestUserID) {
        LoginScene *login = [[LoginScene alloc] init];
        [self addChild:login];
    }
}

@end
