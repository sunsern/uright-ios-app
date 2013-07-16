//
//  GlobalStorage.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//

#import <Foundation/Foundation.h>

#import "LanguageData.h"

@class UserData;

@interface GlobalStorage : NSObject

@property int activeUserID;
@property (nonatomic,strong) LanguageData *languages;
@property (nonatomic,strong) UserData *activeUser;

+ (id)sharedInstance;

// change active user
- (void)switchActiveUser:(int)userID;

- (void)setLanguages:(LanguageData *)languages;

//- (void)saveGlobalData;
//- (void)loadGlobalData;
//- (void)saveUserData;
//- (void)loadUserData;

- (void)clearGlobalData;

@end
