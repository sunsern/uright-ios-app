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
    NSArray *_buttonText; 
}

- (id)init {
    self = [super init];
    if (self) {
        
        int gameWidth = Sparrow.stage.width;
        //int gameHeight = Sparrow.stage.height;
        
        // BG
        SPQuad *background = [SPQuad quadWithWidth:300 height:360 color:0xffffff];
        background.pivotX = background.width / 2;
        background.x = gameWidth / 2;
        background.y = 0;
        background.color = 0xeeeeee;
        
        //SPImage *background = [SPImage imageWithContentsOfFile:@"background.jpg"];
        background.blendMode = SP_BLEND_MODE_NONE;
        [self addChild:background];
        [background addEventListener:@selector(onTouch:)
                            atObject:self forType:SP_EVENT_TYPE_TOUCH];
        
        // Create buttons
        SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big.png"];
        _buttonText = @[@"Sign in", @"Sign in with Facebook"];
        for (int i = 0; i < [_buttonText count]; i++) {
            SPButton *button = [SPButton buttonWithUpState:buttonTexture];
            button.pivotX = button.width / 2;
            button.pivotY = button.height / 2;
            button.x = gameWidth / 2;
            button.y = 200 + 80*i;
            button.scaleX = 1.25;
            button.scaleY = 1.25;
            button.text = _buttonText[i];
            button.name = button.text;
            [self addChild:button];
            [button addEventListener:@selector(onButtonTriggered:)
                            atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
        }
        
        NSArray *labels = @[@"Username", @"password"];
        for (int i=0; i < [labels count]; i++) {
            SPTextField *tf = [SPTextField textFieldWithWidth:120 height:40 text:labels[i]];
            tf.x = gameWidth / 2 - tf.width;
            tf.y = 40 + 40*i;
            tf.color = 0x333333;
            [self addChild:tf];
        }
        _username = [[UITextField alloc] initWithFrame:CGRectMake(gameWidth/2, 30+40, 120, 40)];
        _username.backgroundColor = [UIColor whiteColor];
        _username.borderStyle = UITextBorderStyleRoundedRect;
        _username.autocorrectionType = UITextAutocorrectionTypeNo;
        _username.autocapitalizationType = UITextAutocapitalizationTypeNone;
        [Sparrow.currentController.view addSubview:_username];
        
        _password = [[UITextField alloc] initWithFrame:CGRectMake(gameWidth/2, 30+80, 120, 40)];
        _password.backgroundColor = [UIColor whiteColor];
        _password.borderStyle = UITextBorderStyleRoundedRect;
        _password.secureTextEntry = YES;
        [Sparrow.currentController.view addSubview:_password];
    }
    return self;
}

- (void)adjustUIKits {
    [_username setFrame:CGRectMake(_username.frame.origin.x, self.y + 40,
                                  _username.frame.size.width, _username.frame.size.height)];
    [_password setFrame:CGRectMake(_password.frame.origin.x, self.y + 80,
                                   _password.frame.size.width, _password.frame.size.height)];
}


- (void)onTouch:(SPEvent *)event {
    [_username resignFirstResponder];
    [_password resignFirstResponder];
}


- (UIAlertView *)showAlert:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please wait"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:nil];
    [alert show];
    if(alert != nil) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        indicator.center = CGPointMake(alert.bounds.size.width/2, alert.bounds.size.height-45);
        [indicator startAnimating];
        [alert addSubview:indicator];
    }
    return alert;
}


- (void)onButtonTriggered:(SPEvent *)event {
    [_username resignFirstResponder];
    [_password resignFirstResponder];
    SPButton *button = (SPButton *)event.target;
    if ([button.name isEqualToString:_buttonText[0]]) {
        
        if (_username.text.length > 0 &&
            _password.text.length > 0) {
            UIAlertView *alert = [self showAlert:@"Logging in"];
            [AccountManager loginAsUsername:_username.text
                                   password:_password.text
                                 onComplete:^(BOOL successful){
                                     if (successful) {
                                         [alert dismissWithClickedButtonIndex:0 animated:YES];
                                         [_username removeFromSuperview];
                                         [_password removeFromSuperview];
                                         [self removeFromParent];
                                     } else {
                                         [alert dismissWithClickedButtonIndex:0 animated:YES];
                                         UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Login failed" message:@"Please check your username and password." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                         [errorAlert show];
                                     }
                                 }];
        }
    } else if ([button.name isEqualToString:_buttonText[1]]) {
        UIAlertView *alert = [self showAlert:@"Logging in"];
        [AccountManager loginAsCurrentFacebookUser:^(BOOL successful){
            if (successful) {
                [alert dismissWithClickedButtonIndex:0 animated:YES];
                [_username removeFromSuperview];
                [_password removeFromSuperview];
                [self removeFromParent];
            } else {
                [alert dismissWithClickedButtonIndex:0 animated:YES];
                UIAlertView *errorAlert = [[UIAlertView alloc]
                                           initWithTitle:@"Login failed"
                                           message:@"Cannot authenticate with Facebook"
                                           delegate:self
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
                [errorAlert show];
            }
        }];
    }
}



@end
