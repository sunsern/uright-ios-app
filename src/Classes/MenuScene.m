//
//  MenuScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "MenuScene.h"
#import "LoginScene.h"
#import "Game.h"


@implementation MenuScene {
    LoginScene *login;
}

- (id)init
{
    self = [super init];
    if (self) {
        SPImage *background = [SPImage imageWithContentsOfFile:@"background.jpg"];
        [self addChild:background];
        
        NSString *text = @"To find out how to create your own game out of this scaffold, "
        @"have a look at the 'First Steps' section of the Sparrow website!";
        
        SPTextField *textField = [[SPTextField alloc] initWithWidth:280 height:80 text:text];
        textField.x = (GAME_WIDTH - textField.width) / 2;
        textField.y = GAME_HEIGHT / 2 - 135;
        [self addChild:textField];
        
        SPImage *image = [[SPImage alloc] initWithTexture:[Media atlasTexture:@"sparrow"]];
        image.pivotX = (int)image.width  / 2;
        image.pivotY = (int)image.height / 2;
        image.x = GAME_WIDTH  / 2;
        image.y = GAME_WIDTH / 2 + 40;
        [self addChild:image];
        
        [self addEventListener:@selector(onAdded:)
                      atObject:self
                       forType:SP_EVENT_TYPE_ADDED_TO_STAGE];
        
        
    }
    return self;
}

- (void)loginDone:(SPEvent *)event {
    [self removeChild:login];
    NSLog(@"remove child!");
}

- (void)dealloc {
    [self removeEventListenersAtObject:self forType:SP_EVENT_TYPE_ADDED_TO_STAGE];
}

- (void)onAdded:(SPEvent *)event {
    if (TRUE) {
        login = [[LoginScene alloc] init];
        [login addEventListener:@selector(loginDone:)
                       atObject:self
                        forType:LOGIN_DONE];
        login.x = -100;
        login.y = -100;
        login.pivotX = 0;
        login.pivotY = 0;
        [self addChild:login];
        
        SPTween *tween = [SPTween tweenWithTarget:login time:2.0 transition:SP_TRANSITION_EASE_IN];
        [tween setDelay:1.0];
        [tween animateProperty:@"y" targetValue:0];
        [tween animateProperty:@"x" targetValue:0];
        [[Sparrow juggler] addObject:tween];
        NSLog(@"Added");
    }
}

@end
