//
//  LoginViewController.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/21/13.
//
//

#import <Parse/Parse.h>

#define NS_NOTIFICATION_LOGGED_IN @"logged_in"

@interface LoginViewController : PFLogInViewController <PFLogInViewControllerDelegate,PFSignUpViewControllerDelegate>

@end
