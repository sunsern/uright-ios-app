//
//  GlobalStorage.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//

#import <Foundation/Foundation.h>

#import "Languages.h"

@class UserStorage;

@interface GlobalStorage : NSObject

@property (readonly) int currentUserId;
@property (nonatomic,strong) Languages *languages;
@property (nonatomic,strong) UserStorage *userdata;

+ (id)sharedInstance;

// change active user
- (void)switchToUser:(int)newUserId;

- (void)loadGlobalData;
- (void)loadUserData;

- (void)saveGlobalData;
- (void)saveUserData;

@end
