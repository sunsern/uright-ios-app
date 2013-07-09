//
//  GlobalStorage.m
//  uRight2
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//
//

#import "GlobalStorage.h"
#import "UserStorage.h"
#import "ServerManager.h"
#import "SessionData.h"

#define VERSION 1.0
#define DEFAULT_CHARDELAY 0.9f
#define DEFAULT_LANGUAGE 1

@interface GlobalStorage () {
    dispatch_queue_t serialQueue_;
}
@end

@implementation GlobalStorage

static GlobalStorage *sharedInstance = nil;

+ (GlobalStorage *)sharedInstance {
    if (nil != sharedInstance) {
        return sharedInstance;
    }
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        sharedInstance = [[GlobalStorage alloc] init];
    });
    return sharedInstance;
}

- (void)loadData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // User ID
    NSNumber *uid = [defaults objectForKey:@"currentuserid"];
    if (uid != nil) {
        _currentUserId = [uid intValue];
    } else {
        _currentUserId = 0;
    }
    NSLog(@"> userID = %d", _currentUserId);
    
    // Languages
    _languages = [defaults objectForKey:@"languages"];
    if (_languages == nil) {
        // Load languages from settings.json
        NSString *filePath = [[NSBundle mainBundle]
                              pathForResource:@"settings.json" ofType:@""];
        NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
        NSError *error;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:kNilOptions
                                                                   error:&error];
        _languages = [jsonData objectForKey:@"languages"];
    }
    NSLog(@"> Loaded languages");
    
    // Userdata
    NSDictionary *userData = [defaults objectForKey:
                              [NSString stringWithFormat:
                               @"user-%d-version-%0.1f",_currentUserId,VERSION]];
    if (userData == nil) {
        if (_currentUserId == 0) {
            // Guest account
            _userdata = [[UserStorage alloc] initWithUserId:0
                                                 languageId:DEFAULT_LANGUAGE];
            [_userdata setUsername:@"Guest"];
            [_userdata setPassword:@""];
        } else {
            // Non-guest account
            _userdata = [[UserStorage alloc] initWithUserId:_currentUserId
                                                 languageId:DEFAULT_LANGUAGE];
            [_userdata setUsername:@"unknown"];
            [_userdata setPassword:@""];
        }
        // Default data template
        [_userdata setCharacterDelay:DEFAULT_CHARDELAY];
        NSLog(@"Data for %d doesn't exist. Creating from template", _currentUserId);
    } else {
        _userdata = [[UserStorage alloc] initWithUserId:_currentUserId
                                             languageId:[[userData objectForKey:@"languageId"] intValue]];
        [_userdata setCharacterDelay:[[userData objectForKey:@"characterDelay"] floatValue]];
        [_userdata setUsername:[userData objectForKey:@"username"]];
        [_userdata setPassword:[userData objectForKey:@"password"]];
        [_userdata setClassifiers:[[NSMutableDictionary alloc]
                                   initWithDictionary:
                                   [userData objectForKey:@"classifiers"]]];
        [_userdata setScores:[[NSMutableDictionary alloc]
                              initWithDictionary:[userData objectForKey:@"scores"]]];
        [_userdata setSessions:[[NSMutableArray alloc]
                                initWithArray:[userData objectForKey:@"sessions"]]];
        NSLog(@"Load data for user %d",_currentUserId);
    }
}

- (void)loadUserData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // Userdata
    NSDictionary *userData = [defaults objectForKey:
                              [NSString stringWithFormat:
                               @"user-%d-version-%0.1f",_currentUserId,VERSION]];
    if (userData == nil) {
        if (_currentUserId == 0) {
            // Guest account
            _userdata = [[UserStorage alloc] initWithUserId:0
                                                 languageId:DEFAULT_LANGUAGE];
            [_userdata setUsername:@"Guest"];
            [_userdata setPassword:@""];
        } else {
            // Non-guest account
            _userdata = [[UserStorage alloc] initWithUserId:_currentUserId
                                                 languageId:DEFAULT_LANGUAGE];
            [_userdata setUsername:@"unknown"];
            [_userdata setPassword:@""];
        }
        // Default data template
        [_userdata setCharacterDelay:DEFAULT_CHARDELAY];
        NSLog(@"Data for %d doesn't exist. Creating from template", _currentUserId);
    } else {
        _userdata = [[UserStorage alloc] initWithUserId:_currentUserId
                                             languageId:[[userData objectForKey:@"languageId"] intValue]];
        [_userdata setCharacterDelay:[[userData objectForKey:@"characterDelay"] floatValue]];
        [_userdata setUsername:[userData objectForKey:@"username"]];
        [_userdata setPassword:[userData objectForKey:@"password"]];
        [_userdata setClassifiers:[[NSMutableDictionary alloc]
                                   initWithDictionary:
                                   [userData objectForKey:@"classifiers"]]];
        [_userdata setScores:[[NSMutableDictionary alloc]
                              initWithDictionary:[userData objectForKey:@"scores"]]];
        [_userdata setSessions:[[NSMutableArray alloc]
                                initWithArray:[userData objectForKey:@"sessions"]]];
        NSLog(@"Load data for user %d",_currentUserId);
    }
}


// Async
- (void)saveUserData {
    dispatch_async(serialQueue_, ^{
        // save last active userId
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *userData = @{
        @"languageId":@([_userdata languageId]),
        @"characterDelay":@([_userdata characterDelay]),
        @"classifiers":[_userdata classifiers],
        @"sessions":[_userdata sessions],
        @"username":[_userdata username],
        @"password":[_userdata password],
        @"scores":[_userdata scores] };
        [defaults setObject:userData
                     forKey:[NSString stringWithFormat:@"user-%d-version-%0.1f",
                             _currentUserId,VERSION]];
        NSLog(@"Save user data");
    });
}

// Async
- (void)saveGlobalData {
    dispatch_async(serialQueue_, ^{
        // save last active userId
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@(_currentUserId) forKey:@"currentuserid"];
        [defaults setObject:_languages forKey:@"languages"];
        NSLog(@"Save global data");
    });
}

// Sync
- (void)saveAllData {
    // save last active userId
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(_currentUserId) forKey:@"currentuserid"];
    [defaults setObject:_languages forKey:@"languages"];
    NSDictionary *userData = @{
    @"languageId":@([_userdata languageId]),
    @"characterDelay":@([_userdata characterDelay]),
    @"classifiers":[_userdata classifiers],
    @"sessions":[_userdata sessions],
    @"username":[_userdata username],
    @"password":[_userdata password],
    @"scores":[_userdata scores] };
    [defaults setObject:userData
                 forKey:[NSString stringWithFormat:@"user-%d-version-%0.1f",
                         _currentUserId,VERSION]];
    NSLog(@"Save all data");
}

- (void)switchToUser:(int)newUserId {
    if (_currentUserId != newUserId) {
        [self saveUserData];
        _currentUserId = newUserId;
        [self loadUserData];
        [self saveGlobalData];
    }
}

- (void)showConnectionError {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                    message:@"Connect to the internet to synchronize your data."
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)synchronizeData {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please wait"
                                                    message:@"Synchronizing data..."
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
    
    dispatch_async(serialQueue_, ^{
        // submit saved sessions
        if ([ServerManager isOnline]) {
            NSMutableArray *sessions = [_userdata sessions];
            NSLog(@"%d saved sessions",[sessions count]);
            while ([sessions count] > 0) {
                SessionData *session = [[SessionData alloc]
                                        initWithJSONObject:[sessions objectAtIndex:0]];
                if (![ServerManager submitSessionData:session]) {
                    NSLog(@"Fail to send, aborting");
                    break;
                } else {
                    [sessions removeObjectAtIndex:0];
                    NSLog(@"Session sent!");
                }
            }
        }
        
        // Fetch new data
        NSDictionary *jsonObj = [ServerManager fetchDataForUsername:[_userdata username]
                                                           password:[_userdata password]];
        
        if (jsonObj != nil) {
            _languages = [jsonObj objectForKey:@"languages"];
            [self saveGlobalData];
            
            NSDictionary *classifiers = [jsonObj objectForKey:@"classifiers"];
            [_userdata setClassifiers:[[NSMutableDictionary alloc]
                                       initWithDictionary:classifiers]];
            // rebuild cache
            [_userdata switchToLanguageId:[_userdata languageId]];
            NSLog(@"Classifiers updated");
            [self saveUserData];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert dismissWithClickedButtonIndex:0 animated:YES];
            });
            
        } else {
            [self saveUserData];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert dismissWithClickedButtonIndex:0 animated:YES];
                [self showConnectionError];
            });
        }
    });
}

- (id)init {
    self = [super init];
    if (self) {
        // Create a serial queue
        serialQueue_ = dispatch_queue_create("com.uRight.GlobalStorage", NULL);
    }
    return self;
}

- (void)dealloc {
    dispatch_release(serialQueue_);
}

@end
