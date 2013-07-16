//
//  UserStorage.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//
//

#import <Foundation/Foundation.h>
#import "URJSONSerializable.h"

@class BFClassifier;
@class SessionData;

@interface UserData : NSObject <URJSONSerializable>

@property (readwrite) int userID;
@property (readwrite) int languageID;
@property (nonatomic,copy) NSString *username;
@property (nonatomic,copy) NSString *password;
// { languageID : BFClassifier* }
@property (nonatomic,strong) NSMutableDictionary *classifiers;
// [ JSONObject, ... ]
@property (nonatomic,strong) NSMutableArray *sessions;
// { languageID : NSDictionary* }
@property (nonatomic,strong) NSMutableDictionary *scores;

- (void)addScore:(float)score;

- (NSArray *)scoreArray;

- (float)bestScore;

- (void)addSessionJSON:(id)sessionJSON;

- (void)switchActiveLanguage:(int)langID;

- (BFClassifier *)activeClassifier;

- (void)setClassifier:(BFClassifier *)classifier
          forLanguage:(int)languageID;

@end
