//
//  LoginViewController.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/21/13.
//
//

#import "LoginViewController.h"
#import "AccountManager.h"
#import "MBProgressHUD.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (id)init {
    self = [super init];
    if (self) {
        self.fields = PFLogInFieldsUsernameAndPassword
        | PFLogInFieldsLogInButton
        | PFLogInFieldsSignUpButton
        | PFLogInFieldsPasswordForgotten
        | PFLogInFieldsFacebook;
        
        self.facebookPermissions = @[@"email"];
        
        self.delegate = self;
        self.signUpController.delegate = self;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 240, 100)];
        label.text = @"uRight3";
        label.font = [UIFont fontWithName:@"Chalkduster" size:50];
        label.textAlignment = UITextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.adjustsFontSizeToFitWidth = YES;
        self.logInView.logo = label;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma delegate

- (void)logInViewController:(PFLogInViewController *)logIncontroller
               didLogInUser:(PFUser *)user {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Logging in...";
    [AccountManager loginAsParseUser:user onComplete:^(BOOL successful){
        if (successful) {
            [hud hide:YES];
            //[MBProgressHUD hideHUDForView:self.view animated:YES];
            [logIncontroller dismissModalViewControllerAnimated:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:NS_NOTIFICATION_LOGGED_IN
                                                                object:self];
        } else {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"Server Error"
                                  message:@"Please try again later."
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
        }
    }];
}

- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    // Do nothing.
}


- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
    self.logInView.usernameField.text = [user username];
    self.logInView.passwordField.text = [user password];
    [signUpController dismissModalViewControllerAnimated:YES];
}


- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
    [signUpController dismissModalViewControllerAnimated:NO];
}


- (BOOL)NSStringIsValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = YES;
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}


- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController
           shouldBeginSignUp:(NSDictionary *)info {
    if ([info[@"username"] length] == 0) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Sign Up Error"
                              message:@"Please set a username."
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    else if ([info[@"password"] length] == 0) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Sign Up Error"
                              message:@"Please set a password."
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    else if (![self NSStringIsValidEmail:info[@"email"]]) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"Sign Up Error"
                              message:@"Please enter a valid email address."
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
        return NO;
    }
    return YES;
}


@end
