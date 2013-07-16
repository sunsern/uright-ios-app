//
//  LoginScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "LoginScene.h"
#import "AccountManager.h"

@implementation LoginScene {
    UITextField *_username;
    UITextField *_password;
    SPButton *_loginButton;
    SPButton *_guestButton;
    SPButton *_createButton;
}

- (id)init {
    self = [super init];
    if (self) {
        int GAME_WIDTH = Sparrow.stage.width;
        
        SPImage *background = [SPImage imageWithContentsOfFile:@"background.jpg"];
        background.blendMode = SP_BLEND_MODE_NONE;
        [self addChild:background];
        [background addEventListener:@selector(onTouch:)
                            atObject:self forType:SP_EVENT_TYPE_TOUCH];
        
        // Create buttons
        SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big.png"];
        
        NSArray *buttonText = @[@"Log in", @"Log in with Facebook"];
        for (int i = 0; i < [buttonText count]; i++) {
            SPButton *button = [SPButton buttonWithUpState:buttonTexture];
            button.pivotX = button.width / 2;
            button.pivotY = button.height / 2;
            button.x = GAME_WIDTH / 2;
            button.y = 200 + 80*i;
            button.text = buttonText[i];
            button.name = button.text;
            [self addChild:button];
            [button addEventListener:@selector(onButtonTriggered:)
                            atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
        }
        
        _username = [[UITextField alloc] initWithFrame:CGRectMake(GAME_WIDTH/2, 50, 100, 30)];
        _username.backgroundColor = [UIColor whiteColor];
        _username.borderStyle = UITextBorderStyleRoundedRect;
        _username.autocorrectionType = UITextAutocorrectionTypeNo;
        _username.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [Sparrow.currentController.view addSubview:_username];
        
        _password = [[UITextField alloc] initWithFrame:CGRectMake(GAME_WIDTH/2, 90, 100, 30)];
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
        
    }
    return self;
}


- (void)onTouch:(SPEvent *)event {
    [_username resignFirstResponder];
    [_password resignFirstResponder];
}

- (void)onButtonTriggered:(SPEvent *)event {
    [_username resignFirstResponder];
    [_password resignFirstResponder];
    SPButton *button = (SPButton *)event.target;
    if ([button.name isEqualToString:@"Log in"]) {
        [AccountManager loginAsUsername:_username.text
                               password:_password.text
                             onComplete:^(BOOL successful){
                                 if (successful) {
                                     [_username removeFromSuperview];
                                     [_password removeFromSuperview];
                                     [self removeFromParent];
                                 }
                             }];
    } else if ([button.name isEqualToString:@"Log in with Facebook"]) {
        [AccountManager loginAsCurrentFacebookUser:^(BOOL successful){
            if (successful) {
                [_username removeFromSuperview];
                [_password removeFromSuperview];
                [self removeFromParent];
            }
        }];
    }
}



@end
