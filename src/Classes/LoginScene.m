//
//  LoginScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "LoginScene.h"

@implementation LoginScene {
    UITextField *_username;
    UITextField *_password;
    SPButton *_loginButton;
    SPButton *_guestButton;
    SPButton *_createButton;
    SPImage *_background;
}

- (id)init {
    self = [super init];
    if (self) {
        int GAME_WIDTH = Sparrow.stage.width;
        
        _background = [SPImage imageWithContentsOfFile:@"background.jpg"];
        _background.blendMode = SP_BLEND_MODE_NONE;
        [self addChild:_background];
        
        // Create buttons
        SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big.png"];
        
        _loginButton = [SPButton buttonWithUpState:buttonTexture text:@"Log in"];
        _loginButton.pivotX = _loginButton.width / 2;
        _loginButton.pivotY = _loginButton.height / 2;
        _loginButton.x = self.width / 2;
        _loginButton.y = 200;
        [self addChild:_loginButton];
        
        _createButton = [SPButton buttonWithUpState:buttonTexture text:@"Create a new account"];
        _createButton.pivotX = _createButton.width / 2;
        _createButton.pivotY = _createButton.height / 2;
        _createButton.x = self.width / 2;
        _createButton.y = 280;
        [self addChild:_createButton];
        
        _guestButton = [SPButton buttonWithUpState:buttonTexture text:@"Log in as a guest"];
        _guestButton.pivotX = _guestButton.width / 2;
        _guestButton.pivotY = _guestButton.height / 2;
        _guestButton.x = self.width / 2;
        _guestButton.y = 360;
        [self addChild:_guestButton];
        
        _username = [[UITextField alloc] initWithFrame:CGRectMake(GAME_WIDTH/2, 30, 100, 30)];
        _username.backgroundColor = [UIColor whiteColor];
        _username.borderStyle = UITextBorderStyleRoundedRect;
        _username.autocorrectionType = UITextAutocorrectionTypeNo;
        _username.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [Sparrow.currentController.view addSubview:_username];
        
        _password = [[UITextField alloc] initWithFrame:CGRectMake(GAME_WIDTH/2, 70, 100, 30)];
        _password.backgroundColor = [UIColor whiteColor];
        _password.borderStyle = UITextBorderStyleRoundedRect;
        _password.secureTextEntry = YES;
        [Sparrow.currentController.view addSubview:_password];
        
        SPTextField *usernameLabel = [SPTextField textFieldWithText:@"Username"];
        usernameLabel.x = (GAME_WIDTH - usernameLabel.width)/2 - 10;
        usernameLabel.y = 30;
        usernameLabel.color = 0x333333;
        [self addChild:usernameLabel];
        
        SPTextField *passwordLabel = [SPTextField textFieldWithText:@"Password"];
        passwordLabel.x = (GAME_WIDTH - passwordLabel.width)/2 - 10;
        passwordLabel.y = 70;
        passwordLabel.color = 0x333333;
        [self addChild:passwordLabel];
    
        [_loginButton addEventListener:@selector(onButtonTriggered:) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
        [_guestButton addEventListener:@selector(onButtonTriggered:) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
        [_createButton addEventListener:@selector(onButtonTriggered:) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
        
        [_background addEventListener:@selector(onTouch:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
    }
    return self;
}

- (void)dealloc {
    [_loginButton removeEventListenersAtObject:self forType:SP_EVENT_TYPE_TRIGGERED];
    [_guestButton removeEventListenersAtObject:self forType:SP_EVENT_TYPE_TRIGGERED];
    [_background removeEventListenersAtObject:self forType:SP_EVENT_TYPE_TOUCH];
}


- (void)onTouch:(SPEvent *)event {
    [_username resignFirstResponder];
    [_password resignFirstResponder];
}

- (void)onButtonTriggered:(SPEvent *)event {
    [_username resignFirstResponder];
    [_password resignFirstResponder];
    SPButton *button = (SPButton *)event.target;
    if (button == _loginButton) {
        NSLog(@"log in as %@ : %@", [_username text], [_password text]);
        [self dispatchEvent:[SPEvent eventWithType:LOGIN_DONE]];
    } else if (button == _createButton) {
        NSLog(@"create account");
        [self dispatchEvent:[SPEvent eventWithType:LOGIN_DONE]];
    } else {
        NSLog(@"guest");
        [self dispatchEvent:[SPEvent eventWithType:LOGIN_DONE]];
    }
}


@end
