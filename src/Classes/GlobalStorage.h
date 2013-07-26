//
//  GlobalStorage.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//

#import <Foundation/Foundation.h>

@class Userdata;
@class Charset;

@interface GlobalStorage : NSObject

@property int activeUserID;
@property (nonatomic,strong) Userdata *activeUserdata;
@property (nonatomic,strong) NSArray *charsets;

+ (id)sharedInstance;

+ (void)clearGlobalData;

- (void)switchActiveUser:(int)userID onComplete:(void(^)(void))completeBlock;

- (Charset *)charsetByID:(int)charsetID;

@end
