//
//  GlobalStorage.h
//  uRight2
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//
//

#import <Foundation/Foundation.h>

@class UserStorage;

@interface GlobalStorage : NSObject

@property (readonly) int currentUserId;
// (key:value) = (languageID, jsonObject)
@property (nonatomic,strong) NSDictionary *languages;
@property (nonatomic,strong) UserStorage *userdata;

+ (id)sharedInstance;

// change active user
- (void)switchToUser:(int)newUserId;

- (void)loadData;
- (void)loadUserData;
- (void)saveUserData;
- (void)saveGlobalData;
- (void)saveAllData;

// sync data
- (void)synchronizeData;

@end
