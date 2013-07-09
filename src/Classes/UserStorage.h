//
//  UserStorage.h
//  uRight2
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//
//

#import <Foundation/Foundation.h>

@class DtwClassifier;
@class ExampleSet;

@interface UserStorage : NSObject

@property (readonly) int userId;
@property (readonly) int languageId;
@property (readwrite) float characterDelay;
@property (nonatomic,copy) NSString *username;
@property (nonatomic,copy) NSString *password;
// (key:value) = (languageId:jsonObject)
@property (nonatomic,strong) NSMutableDictionary *classifiers;
// Each entry is jsonObject
@property (nonatomic,strong) NSMutableArray *sessions;
// (key:value) = (languageId:NSDictionary)
@property (nonatomic,strong) NSMutableDictionary *scores;
@property (nonatomic,strong,readonly) ExampleSet *exampleSet;
@property (nonatomic,strong,readonly) DtwClassifier *dtwClassifier;
@property (nonatomic,strong,readonly) NSArray *labelArray;

- (id)initWithUserId:(int)userId languageId:(int)languageId;

- (void)addScore:(float)score;

- (NSArray *)scoreArray;

- (float)bestScore;

- (void)addSession:(NSDictionary *)jsonData;

- (void)switchToLanguageId:(int)langId;

- (int)classifierId;

- (NSString *)languageName;

- (void)updateClassifier:(NSDictionary *)c
             forLanguage:(int)languageId;

@end
