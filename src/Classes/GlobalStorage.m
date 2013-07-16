//
//  GlobalStorage.m
//  uRight2
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//
//

#import "GlobalStorage.h"

#import "UserData.h"
#import "BFClassifier.h"

#define STORAGE_VERSION 3.0
#define SETTINGS_FILE @"settings.json"
#define ENGLISH_CLASSIFIER @"dtw_classifier_user_1.json"
#define DEFAULT_LANGUAGE_ID 1 // English

#define VERBOSE YES

static GlobalStorage *__sharedInstance = nil;

@implementation GlobalStorage {
    dispatch_queue_t _serialQueue;
}

+ (GlobalStorage *)sharedInstance {
    if (nil != __sharedInstance) {
        return __sharedInstance;
    }
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        __sharedInstance = [[self alloc] init];
    });
    return __sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        // Create a serial queue for dealing with NSUserDefaults
        _serialQueue = dispatch_queue_create("uRight3.GlobalStorage", NULL);
        [self loadGlobalData];
        [self loadUserData];
    }
    return self;
}

- (void)dealloc {
    dispatch_release(_serialQueue);
}

- (void)saveGlobalData {
    dispatch_async(_serialQueue, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@(_activeUserID) forKey:@"activeUserID"];
        [defaults setObject:[_languages toJSONObject] forKey:@"languages"];
        if (VERBOSE) NSLog(@"App-wide data saved.");
    });
}

- (void)loadGlobalData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    // Get last active userID
    id lastUserID = [defaults objectForKey:@"activeUserID"];
    if (lastUserID == nil) {
        _activeUserID = kURGuestUserID;
    } else {
        _activeUserID = [lastUserID intValue];
    }
    // Language data
    NSDictionary *langData = [defaults objectForKey:@"languages"];
    if (langData == nil) {
        // Load language data from file
        NSDictionary *jsonObj = [[self class] loadJSONFromFile:SETTINGS_FILE];
        _languages = [[LanguageData alloc]
                      initWithJSONObject:jsonObj[@"languages"]];
    }
    else {
        _languages = [[LanguageData alloc]
                      initWithJSONObject:langData];
    }
    if (VERBOSE) NSLog(@"Loaded %d languages",[_languages.languages count]);
}


- (void)saveUserData {
    dispatch_async(_serialQueue, ^{
        // save last active userID
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[_activeUser toJSONObject]
                     forKey:[NSString stringWithFormat:@"user-%d-version-%0.1f",
                             _activeUserID, STORAGE_VERSION]];
        if (VERBOSE) NSLog(@"User-specific data saved.");
    });
}


- (void)loadUserData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id userData = [defaults objectForKey:
                              [NSString stringWithFormat:
                               @"user-%d-version-%0.1f",
                               _activeUserID,STORAGE_VERSION]];
    if (userData == nil) {
        // No user data found. Create an empty guest account.
        _activeUser = [[UserData alloc] init];
        _activeUser.userID = _activeUserID;
        _activeUser.languageID = DEFAULT_LANGUAGE_ID;
        if (_activeUserID == kURGuestUserID) {
            _activeUser.username = @"Guest";
            _activeUser.password = @"";
        } else {
            _activeUser.username = @"unknown";
            _activeUser.password = @"";
        }
        // Create English classifier
        NSDictionary *classifierJSON = [[self class]
                                        loadJSONFromFile:ENGLISH_CLASSIFIER];
        BFClassifier *classifier = [[BFClassifier alloc]
                                    initWithJSONObject:classifierJSON];
        [_activeUser setClassifier:classifier forLanguage:DEFAULT_LANGUAGE_ID];
        
        if (VERBOSE) {
            NSLog(@"Data for %d doesn't exist. Creating from template",
                  _activeUserID);
        }
    } else {
        _activeUser = [[UserData alloc] initWithJSONObject:userData];
        if (VERBOSE) NSLog(@"Load data for user %d",_activeUserID);
    }
}

- (void)switchActiveUser:(int)userID {
    if (_activeUserID != userID) {
        [self saveUserData];
        _activeUserID = userID;
        [self loadUserData];
        [self saveGlobalData];
    }
}


- (void)setLanguages:(LanguageData *)languages {
    _languages = languages;
    [self saveGlobalData];
}

- (void)clearGlobalData {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    NSLog(@"RESET APP DATA");

    [self loadGlobalData];
    [self loadUserData];
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
