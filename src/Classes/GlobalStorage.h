//
//  GlobalStorage.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//

#import <Foundation/Foundation.h>

@class UserStorage;

@interface GlobalStorage : NSObject

@property (readonly) int currentUserId;
// (key:value) = (languageID, jsonObject)
@property (nonatomic,strong) NSDictionary *langDefinitions;
@property (nonatomic,strong) UserStorage *userdata;

+ (id)sharedInstance;

// change active user
- (void)switchToUser:(int)newUserId;

- (void)loadGlobalData;
- (void)loadUserData;

- (void)saveGlobalData;
- (void)saveUserData;
- (void)saveAllData;

// sync data
- (void)synchronizeData;


@end
