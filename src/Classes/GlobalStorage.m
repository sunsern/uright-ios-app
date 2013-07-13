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

#define VERSION 3.0
#define VERBOSE YES
#define DEFAULT_LANGUAGE 1
#define GUEST_USER_ID 0
#define SETTINGS_FILE @"settings.json"

static GlobalStorage *sharedInstance = nil;

@implementation GlobalStorage {
    dispatch_queue_t serialQueue_;
}

+ (GlobalStorage *)sharedInstance {
    if (nil != sharedInstance) {
        return sharedInstance;
    }
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
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


- (void)loadGlobalData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Read User ID
    NSNumber *uid = [defaults objectForKey:@"currentuserid"];
    if (uid != nil) {
        _currentUserId = [uid intValue];
    } else {
        _currentUserId = GUEST_USER_ID;
    }
    if (VERBOSE) NSLog(@"Current userId = %d", _currentUserId);
    
    // Language defnitions
    _langDefinitions = [defaults objectForKey:@"languages"];
    if (_langDefinitions == nil) {
        // Load languages from settings.json
        NSString *filePath = [[NSBundle mainBundle]
                              pathForResource:SETTINGS_FILE ofType:@""];
        NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
        NSError *error;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:kNilOptions
                                                                   error:&error];
        _langDefinitions = jsonData[@"languages"];
    }
    NSLog(@"Loaded %d languages",[_langDefinitions count]);
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
            _userdata = [[UserStorage alloc] initWithUserId:GUEST_USER_ID
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



@end
