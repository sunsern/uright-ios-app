//
//  GlobalStorage.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//
//

#import "GlobalStorage.h"

#import "UserData.h"
#import "Charset.h"
#import "ServerManager.h"

// Hack inject
#import "BFClassifier.h"
#import "BFPrototype.h"

#define STORAGE_VERSION 3.0
#define SETTINGS_FILE @"settings.json"

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
        DEBUG_PRINT(@"[GS] Singleton created.");
        
        [self loadGlobalData];
        [self loadUserData];
    }
    return self;
}

- (void)dealloc {
    dispatch_release(_serialQueue);
}

- (void)saveGlobalData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // Save active userID
    [defaults setObject:@(_activeUserID) forKey:@"activeUserID"];
    
    // Save charsets
    NSMutableArray *charsets = [[NSMutableArray alloc] init];
    for (Charset *cs in _charsets) {
        [charsets addObject:[cs toJSONObject]];
    }
    [defaults setObject:charsets forKey:@"charsets"];
    
    DEBUG_PRINT(@"[GS] Global data saved.");
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
    
    // Character set
    BOOL loadedCharset = NO;
    // check for langauge data online
    if ([ServerManager isOnline]) {
        NSArray *charsets = [ServerManager fetchCharsets];
        if (charsets) {
            _charsets = charsets;
            loadedCharset = YES;
            DEBUG_PRINT(@"[GS] Loaded %d character sets from server",[_charsets count]);
        }
    }
    if (!loadedCharset) {
        NSArray *charsetsJSON = [defaults objectForKey:@"charsets"];
        if (charsetsJSON == nil) {
            // Not found, load charset data from local file
            NSArray *jsonObj = [[self class] loadJSONFromFile:SETTINGS_FILE];
            NSMutableArray *charsets = [[NSMutableArray alloc] init];
            for (id eachCharset in jsonObj) {
                [charsets addObject:[[Charset alloc] initWithJSONObject:eachCharset]];
            }
            _charsets = charsets;
            DEBUG_PRINT(@"[GS] Loaded %d character sets from file",[_charsets count]);
        }
        else {
            NSMutableArray *charsets = [[NSMutableArray alloc] init];
            for (id eachCharset in charsetsJSON) {
                [charsets addObject:[[Charset alloc] initWithJSONObject:eachCharset]];
            }
            _charsets = charsets;
            DEBUG_PRINT(@"[GS] Loaded %d character sets from cache",[_charsets count]);
        }
    }
}


- (void)saveUserData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[_activeUserData toJSONObject]
                 forKey:[NSString stringWithFormat:@"user-%d-version-%0.1f",
                         _activeUserID, STORAGE_VERSION]];
    DEBUG_PRINT(@"[GS] User-specific data saved.");
}


- (void)loadUserData {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id userData = [defaults objectForKey:
                   [NSString stringWithFormat:
                    @"user-%d-version-%0.1f",
                    _activeUserID, STORAGE_VERSION]];
     
    if (userData == nil) {
        // No user data found. Create an empty user data.
        _activeUserData = [UserData newUserData:_activeUserID];
        
        // Set the first charset to active
        Charset *activeCharset = _charsets[0];
        _activeUserData.activeCharacters = [[NSMutableArray alloc]
                                            initWithArray:[activeCharset characters]];
        
        DEBUG_PRINT(@"[GS] Data for %d doesn't exist. Created from template", _activeUserID);
    } else {
        _activeUserData = [[UserData alloc] initWithJSONObject:userData];
        DEBUG_PRINT(@"[GS] Load data for user %d",_activeUserID);
    }
    
    // check for new prototypes
    if ([ServerManager isOnline]) {
        NSDictionary *protosets = [ServerManager fetchProtosets:_activeUserID];
        if (protosets) {
            _activeUserData.protosets = protosets;
            DEBUG_PRINT(@"[GS] Loaded %d protosets from server",[protosets count]);
        }
    }
}

- (void)switchActiveUser:(int)userID onComplete:(void(^)(void))completeBlock; {
    dispatch_sync(_serialQueue, ^{
        if (_activeUserID != userID) {
            DEBUG_PRINT(@"[GS] Switching user %d -> %d",_activeUserID, userID);
            if (_activeUserData != kURGuestUserID) {
                [self saveUserData];
            }
            _activeUserID = userID;
            [self loadUserData];
            [self saveGlobalData];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completeBlock();
        });
    });
}

+ (void)clearGlobalData {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    DEBUG_PRINT(@"[GS] RESET APP DATA");
}

// Helper method
+ (id)loadJSONFromFile:(NSString *)filename {
    NSString *filePath = [[NSBundle mainBundle]
                          pathForResource:filename ofType:@""];
    NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
    NSError *error;
    return [NSJSONSerialization JSONObjectWithData:data
                                           options:kNilOptions
                                             error:&error];
}




@end
