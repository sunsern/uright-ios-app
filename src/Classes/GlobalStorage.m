//
//  GlobalStorage.m
//  uRight2
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//
//

#import "GlobalStorage.h"
#import "UserStorage.h"
#import "BFClassifier.h"

#define VERSION 3.0
#define DEFAULT_LANGUAGE_ID 1 // English
#define GUEST_USER_ID 0
#define SETTINGS_FILE @"settings.json"
#define ENGLISH_CLASSIFIER @"dtw_classifier_user_1.json"

#define VERBOSE YES

static GlobalStorage *sharedInstance = nil;

@implementation GlobalStorage {
    dispatch_queue_t _serialQueue;
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
        _serialQueue = dispatch_queue_create("uRight3.GlobalStorage", NULL);
    }
    return self;
}

- (void)dealloc {
    dispatch_release(_serialQueue);
}

- (void)saveGlobalData {
    dispatch_async(_serialQueue, ^{
        // save last active userId
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@(_currentUserId) forKey:@"currentuserid"];
        [defaults setObject:[_languages toJSONObject] forKey:@"languages"];
        if (VERBOSE) NSLog(@"Save global data");
    });
}

- (void)loadGlobalData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Read the user id from storage
    NSNumber *uid = [defaults objectForKey:@"currentuserid"];
    if (uid == nil) {
        _currentUserId = GUEST_USER_ID;
    } else {
        _currentUserId = [uid intValue];
    }
    if (VERBOSE) NSLog(@"Current userId = %d", _currentUserId);
    
    // Language Info
    NSDictionary *langInfo = [defaults objectForKey:@"languages"];
    if (langInfo == nil) {
        // Load languages
        NSDictionary *jsonObj = [[self class] loadJSONFromFile:SETTINGS_FILE];
        _languages = [[Languages alloc]
                      initWithJSONObject:jsonObj[@"languages"]];
    }
    else {
        _languages = [[Languages alloc]
                      initWithJSONObject:langInfo];
    }
    if (VERBOSE) NSLog(@"Loaded %d languages",[_languages.languages count]);
}

- (void)saveUserData {
    dispatch_async(_serialQueue, ^{
        // save last active userId
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[_userdata toJSONObject]
                     forKey:[NSString stringWithFormat:@"user-%d-version-%0.1f",
                             _currentUserId, VERSION]];
        if (VERBOSE) NSLog(@"Save user data");
    });
}

- (void)loadUserData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id userData = [defaults objectForKey:
                              [NSString stringWithFormat:
                               @"user-%d-version-%0.1f",_currentUserId,VERSION]];
    if (userData == nil) {
        // Guest account
        _userdata = [[UserStorage alloc] init];
        _userdata.userId = _currentUserId;
        _userdata.languageId = DEFAULT_LANGUAGE_ID;
        if (_currentUserId == GUEST_USER_ID) {
            _userdata.username = @"Guest";
            _userdata.password = @"";
        } else {
            _userdata.username = @"unknown";
            _userdata.password = @"";
        }
        // Create English classifier
        NSDictionary *classifierJSON = [[self class]
                                        loadJSONFromFile:ENGLISH_CLASSIFIER];
        BFClassifier *classifier = [[BFClassifier alloc]
                                    initWithJSONObject:classifierJSON];
        [_userdata setClassifier:classifier forLanguage:1];
        
        if (VERBOSE) {
            NSLog(@"Data for %d doesn't exist. Creating from template",
                  _currentUserId);
        }
    } else {
        _userdata = [[UserStorage alloc] initWithJSONObject:userData];
        if (VERBOSE) NSLog(@"Load data for user %d",_currentUserId);
    }
}

- (void)switchToUser:(int)newUserId {
    if (_currentUserId != newUserId) {
        [self saveUserData];
        _currentUserId = newUserId;
        [self loadUserData];
        [self saveGlobalData];
    }
}

// Helper method
+ (NSDictionary *)loadJSONFromFile:(NSString *)filename {
    NSString *filePath = [[NSBundle mainBundle]
                          pathForResource:filename ofType:@""];
    NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
    NSError *error;
    return [NSJSONSerialization JSONObjectWithData:data
                                           options:kNilOptions
                                             error:&error];
}


@end
