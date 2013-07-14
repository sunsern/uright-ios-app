//
//  UserStorage.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//
//

#import <Foundation/Foundation.h>

@class BFClassifier;
@class SessionData;

@interface UserStorage : NSObject

@property (readwrite) int userId;
@property (readwrite) int languageId;
@property (nonatomic,copy) NSString *username;
@property (nonatomic,copy) NSString *password;
// key=languageId, value=BFClassifier
@property (nonatomic,strong) NSMutableDictionary *classifiers;
// array of json representation
@property (nonatomic,strong) NSMutableArray *sessions;
// key=languageId, value=score_struct
@property (nonatomic,strong) NSMutableDictionary *scores;

// Serialization
- (id)initWithJSONObject:(id)jsonObj;
- (id)toJSONObject;

// Add a new score
- (void)addScore:(float)score;
- (NSArray *)scoreArray;
- (float)bestScore;

/////////////////////

- (void)addSessionJSON:(id)sessionJSON;

- (void)switchToLanguageId:(int)langId;

- (void)setClassifier:(BFClassifier *)classifier
          forLanguage:(int)languageId;

////////////////////

- (BFClassifier *)classifier;

- (NSString *)languageName;

@end
