//
//  GlobalStorage.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//

#import <Foundation/Foundation.h>

@class UserData;

@interface GlobalStorage : NSObject

@property int activeUserID;
@property (nonatomic,strong) UserData *activeUserData;
// Available character sets (Pre-defined by server)
@property (nonatomic,strong) NSArray *charsets;

+ (id)sharedInstance;

+ (void)clearGlobalData;

- (void)switchActiveUser:(int)userID;

@end
