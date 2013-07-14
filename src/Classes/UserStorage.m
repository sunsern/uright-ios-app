//
//  UserStorage.m
//  uRight2
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//
//

#import "UserStorage.h"

#import "BFClassifier.h"
#import "SessionData.h"

#define kMaxScoreHistory 10

@implementation UserStorage

- (id)init {
    self = [super init];
    if (self) {
        _userId = -1;
        _languageId = -1;
        _username = @"";
        _password = @"";
        _classifiers = [[NSMutableDictionary alloc] init];
        _sessions = [[NSMutableArray alloc] init];
        _scores = [[NSMutableDictionary alloc] init];        
    }
    return self;
}

- (id)initWithJSONObject:(NSDictionary *)jsonObj {
    self = [super init];
    if (self) {
        _userId = [jsonObj[@"userId"] intValue];
        _languageId = [jsonObj[@"languageId"] intValue];
        _username = [jsonObj[@"username"] copy];
        _password = [jsonObj[@"password"] copy];
        _classifiers = [[NSMutableDictionary alloc] init];
        NSDictionary *classifiers = jsonObj[@"classifiers"];
        for (id key in classifiers) {
            _classifiers[key] = [[BFClassifier alloc]
                                 initWithJSONObject:classifiers[key]];
        }
        _sessions = [[NSMutableArray alloc]
                     initWithArray:jsonObj[@"sessions"]];
        _scores = [[NSMutableDictionary alloc]
                   initWithDictionary:jsonObj[@"scores"]];
    }
    return self;
}


- (NSDictionary *)toJSONObject {
    NSMutableDictionary *jsonObj = [[NSMutableDictionary alloc] init];
    jsonObj[@"userId"] = @(_userId);
    jsonObj[@"languageId"] = @(_languageId);
    jsonObj[@"username"] = _username;
    jsonObj[@"password"] = _password;
    jsonObj[@"sessions"] = _sessions;
    jsonObj[@"scores"] = _scores;
    NSMutableDictionary *classifiers = [[NSMutableDictionary alloc] init];
    for (id key in _classifiers) {
        classifiers[key] = [_classifiers[key] toJSONObject];
    }
    jsonObj[@"classifiers"] = classifiers;
    return jsonObj;
}

- (void)addScore:(float)score {
    NSString *key = [@(_languageId) stringValue];
    NSDictionary *scoreStruct = _scores[key];
    if (scoreStruct != nil) {
        float max_score = [scoreStruct[@"maxscore"] floatValue];
        float avg_score = [scoreStruct[@"avgscore"] floatValue];
        int num_sessions = [scoreStruct[@"numsessions"] intValue];
        NSMutableArray *scoreArray = [[NSMutableArray alloc] initWithArray:
                                      scoreStruct[@"scores"]];
        if (score > max_score) {
            max_score = score;
        }
        avg_score = (avg_score * num_sessions + score) / (num_sessions + 1);
        num_sessions++;
        while ([scoreArray count] >= kMaxScoreHistory) {
            [scoreArray removeObjectAtIndex:0];
        }
        [scoreArray addObject:[NSNumber numberWithFloat:score]];
        NSDictionary *newScoreStruct = @{@"maxscore":@(max_score),
                                         @"avgscore":@(avg_score),
                                         @"numsessions":@(num_sessions),
                                         @"scores":scoreArray};
        _scores[key] = newScoreStruct;
    } else {
        NSDictionary *newScoreStruct = @{@"maxscore":@(score),
                                         @"avgscore":@(score),
                                         @"numsessions":@(1),
                                         @"scores":@[@(score)]};
        _scores[key] = newScoreStruct;
    }
}

- (NSArray *)scoreArray {
    return _scores[[@(_languageId) stringValue]][@"scores"];
}

- (float)bestScore {
    NSDictionary *scoreStruct = _scores[[@(_languageId) stringValue]];
    if (scoreStruct == nil) {
        return 0.0;
    } else {
        return [scoreStruct[@"maxscore"] floatValue];
    }
}

- (void)addSessionJSON:(id)sessionJSON {
    [_sessions addObject:sessionJSON];
}

// Build cache
- (void)switchToLanguageId:(int)langId {
    _languageId = langId;
}

- (void)setClassifier:(BFClassifier *)classifier
          forLanguage:(int)languageId {
    _classifiers[[@(languageId) stringValue]] = classifier;
}

- (BFClassifier *)classifier {
    return _classifiers[[@(_languageId) stringValue]];
}

- (NSString *)languageName {
    GlobalStorage *gs = [GlobalStorage sharedInstance];
    LanguageInfo *langInfo = [gs.languages languageWithId:_languageId];
    return langInfo.languageName;
}


@end
