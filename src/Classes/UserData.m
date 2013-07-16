//
//  UserStorage.m
//  uRight2
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//
//

#import "UserData.h"

#import "BFClassifier.h"
#import "SessionData.h"

#define kMaxScoreHistory 10

@implementation UserData

- (id)init {
    self = [super init];
    if (self) {
        _userID = -1;
        _languageID = -1;
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
        _userID = [jsonObj[@"userID"] intValue];
        _languageID = [jsonObj[@"languageID"] intValue];
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
    jsonObj[@"userID"] = @(_userID);
    jsonObj[@"languageID"] = @(_languageID);
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
    NSString *key = [@(_languageID) stringValue];
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
    return _scores[[@(_languageID) stringValue]][@"scores"];
}

- (float)bestScore {
    NSDictionary *scoreStruct = _scores[[@(_languageID) stringValue]];
    if (scoreStruct == nil) {
        return 0.0;
    } else {
        return [scoreStruct[@"maxscore"] floatValue];
    }
}

- (void)addSessionJSON:(id)sessionJSON {
    [_sessions addObject:sessionJSON];
}


- (void)switchActiveLanguage:(int)langID {
    GlobalStorage *gs = [GlobalStorage sharedInstance];
    if ([[gs languages] languageWithID:langID] != nil) {
        _languageID = langID;
    }
}

- (void)setClassifier:(BFClassifier *)classifier
          forLanguage:(int)languageID {
    _classifiers[[@(languageID) stringValue]] = classifier;
}

- (BFClassifier *)activeClassifier {
    return _classifiers[[@(_languageID) stringValue]];
}


@end
