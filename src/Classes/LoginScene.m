//
//  LoginScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "LoginScene.h"
#import "AccountManager.h"

#define WINDOW_WIDTH 240
#define WINDOW_HEIGHT 400
#define WINDOW_Y_OFFSET 80

#define TF_Y_OFFSET 40
#define BTN_Y_OFFSET 170
#define BTN_Y_SPACING 120

@implementation LoginScene {
    UITextField *_username;
    UITextField *_password;
    NSArray *_buttonText;
}

- (id)init {
    self = [super init];
    if (self) {
        int gameWidth = Sparrow.stage.width;
        int gameHeight = Sparrow.stage.height;
        
        // Background
        SPQuad *background = [SPQuad quadWithWidth:gameWidth
                                            height:gameHeight];
        background.color = 0x333333;
        background.alpha = 0.8;
        [self addChild:background];
        [background addEventListener:@selector(removeKeyboard)
                            atObject:self
                             forType:SP_EVENT_TYPE_TOUCH];
        
        // Window
        SPQuad *window = [SPQuad quadWithWidth:WINDOW_WIDTH
                                        height:WINDOW_HEIGHT];
        window.pivotX = window.width / 2;
        window.pivotY = 0;
        window.x = gameWidth / 2;
        window.y = WINDOW_Y_OFFSET;
        window.color = 0xeeeeee;
        //SPImage *window = [SPImage imageWithContentsOfFile:@"window.jpg"];
        //window.blendMode = SP_BLEND_MODE_NONE;
        [self addChild:window];
        [window addEventListener:@selector(removeKeyboard)
                        atObject:self
                         forType:SP_EVENT_TYPE_TOUCH];
        
        
        // Textfields
        int tf_width = 140;
        int tf_height = 40;
        _username = [[UITextField alloc]
                     initWithFrame:CGRectMake((gameWidth - tf_width)/2,
                                              window.y + TF_Y_OFFSET,
                                              tf_width,
                                              tf_height)];
        _username.backgroundColor = [UIColor whiteColor];
        _username.borderStyle = UITextBorderStyleRoundedRect;
        _username.autocorrectionType = UITextAutocorrectionTypeNo;
        _username.autocapitalizationType = UITextAutocapitalizationTypeNone;
        _username.placeholder = @"Username";
        _username.textAlignment = UITextAlignmentCenter;
        _username.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _username.delegate = self;
        [Sparrow.currentController.view addSubview:_username];
        
        _password = [[UITextField alloc]
                     initWithFrame:CGRectMake((gameWidth - tf_width)/2,
                                              window.y + TF_Y_OFFSET + tf_height + 5,
                                              tf_width,
                                              tf_height)];
        _password.backgroundColor = [UIColor whiteColor];
        _password.borderStyle = UITextBorderStyleRoundedRect;
        _password.secureTextEntry = YES;
        _password.placeholder = @"Password";
        _password.textAlignment = UITextAlignmentCenter;
        _password.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _password.delegate = self;
        [Sparrow.currentController.view addSubview:_password];
        
        
        // Create buttons
        SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big.png"];
        _buttonText = @[@"Sign in", @"Sign in with Facebook"];
        for (int i = 0; i < [_buttonText count]; i++) {
            SPButton *button = [SPButton buttonWithUpState:buttonTexture];
            button.pivotX = button.width / 2;
            button.pivotY = button.height / 2;
            button.x = gameWidth / 2;
            button.y = window.y + BTN_Y_OFFSET + BTN_Y_SPACING*i;
            button.scaleX = 1.25;
            button.scaleY = 1.25;
            button.text = _buttonText[i];
            button.name = button.text;
            [self addChild:button];
            [button addEventListener:@selector(buttonTriggered:)
                            atObject:self
                             forType:SP_EVENT_TYPE_TRIGGERED];
            
            if (i > 0) {
                SPTextField *or = [SPTextField textFieldWithText:@"-- or --"];
                or.width = 40;
                or.height = 20;
                or.pivotX = or.width / 2;
                or.pivotY = or.height / 2;
                or.x = gameWidth / 2;
                or.y = button.y - BTN_Y_SPACING/2;
                or.color = 0x555555;
                [self addChild:or];
            }
        }
        NSString *link = @"Don't have an account?\n Visit "
        "http://fpga1.ucsd.edu/uright to create an account.";
        SPTextField *linktf = [SPTextField textFieldWithText:link];
        linktf.width = WINDOW_WIDTH;
        linktf.height = 40;
        linktf.pivotX = linktf.width / 2;
        linktf.x = gameWidth / 2;
        linktf.y = WINDOW_Y_OFFSET + WINDOW_HEIGHT - linktf.height;
        linktf.autoScale = YES;
        //linktf.border = YES;
        linktf.color = 0x0000ff;
        [self addChild:linktf];
        [linktf addEventListener:@selector(openBrowser)
                        atObject:self
                         forType:SP_EVENT_TYPE_TOUCH];
    }
    return self;
}

- (void)openBrowser {
    NSString *urlString = @"http://fpga1.ucsd.edu/uright";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}

- (void)removeKeyboard {
    [_username resignFirstResponder];
    [_password resignFirstResponder];
}

- (void)buttonTriggered:(SPEvent *)event {
    [self removeKeyboard];
    SPButton *button = (SPButton *)event.target;
    if ([button.name isEqualToString:_buttonText[0]]) {
        if (_username.text.length > 0 &&
            _password.text.length > 0) {
            UIAlertView *alert = [self showPleaseWait:[NSString stringWithFormat:
                                                  @"Signing in as %@", _username.text]];
            [AccountManager loginAsUsername:_username.text
                                   password:_password.text
                                 onComplete:^(BOOL successful){
                                     if (successful) {
                                         [alert dismissWithClickedButtonIndex:0 animated:YES];
                                         [_username removeFromSuperview];
                                         [_password removeFromSuperview];
                                         [self shootUpAndClose];
                                         //[self removeFromParent];
                                     } else {
                                         [alert dismissWithClickedButtonIndex:0 animated:YES];
                                         [self showErrorMsg:@"Please check your username and password."
                                                      title:@"Login failed"];
                                     }
                                 }];
        }
    } else if ([button.name isEqualToString:_buttonText[1]]) {
        UIAlertView *alert = [self showPleaseWait:@"Signing in with Facebook"];
        [AccountManager loginAsCurrentFacebookUser:^(BOOL successful){
            if (successful) {
                [alert dismissWithClickedButtonIndex:0 animated:YES];
                [_username removeFromSuperview];
                [_password removeFromSuperview];
                //[self removeFromParent];
                [self shootUpAndClose];
            } else {
                [alert dismissWithClickedButtonIndex:0 animated:YES];
                [self showErrorMsg:@"Error signing in with Facebook"
                             title:@"Login failed"];
            }
        }];
    }
}

- (void)showErrorMsg:(NSString *)message title:(NSString *)title {
    UIAlertView *errorMsg = [[UIAlertView alloc]
                             initWithTitle:title
                             message:message
                             delegate:self
                             cancelButtonTitle:@"OK"
                             otherButtonTitles:nil];
    [errorMsg show];
}


- (UIAlertView *)showPleaseWait:(NSString *)message {
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _username) {
        [_password becomeFirstResponder];
    } else if (textField == _password) {
        [textField resignFirstResponder];
    }
    return YES;
}

@end
