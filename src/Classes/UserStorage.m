//
//  UserStorage.m
//  uRight2
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//
//

#import "UserStorage.h"

#import "ExampleSet.h"

#define kMaxScoreHistory 10
#define HEBREW_LANGUAGE_ID 3

@implementation UserStorage

- (id)initWithUserId:(int)userId languageId:(int)languageId {
    self = [super init];
    if (self) {
        _userId = userId;
        _languageId = languageId;
        _sessions = [[NSMutableArray alloc] init];
        _scores = [[NSMutableDictionary alloc] init];
        _classifiers = [[NSMutableDictionary alloc]
                        initWithDictionary:[self defaultClassifier]];
        _sessions = [[NSMutableArray alloc] init];
        _scores = [[NSMutableDictionary alloc] init];        
    }
    return self;
}

- (void)addScore:(float)score {
    NSString *key = [NSString stringWithFormat:@"%d",_languageId];
    NSDictionary *scoreStruct = [_scores objectForKey:key];
    if (scoreStruct != nil) {
        float max_score = [[scoreStruct objectForKey:@"maxscore"] floatValue];
        float avg_score = [[scoreStruct objectForKey:@"avgscore"] floatValue];
        int num_sessions = [[scoreStruct objectForKey:@"numsessions"] intValue];
        NSMutableArray *scoreArray = [[NSMutableArray alloc] initWithArray:
                                      [scoreStruct objectForKey:@"scores"]];
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
        [_scores setObject:newScoreStruct forKey:key];
    } else {
        NSDictionary *newScoreStruct = @{@"maxscore":@(score),
                                         @"avgscore":@(score),
                                         @"numsessions":@(1),
                                         @"scores":@[@(score)]};
        [_scores setObject:newScoreStruct forKey:key];
    }
}

- (NSArray *)scoreArray {
    NSString *key = [NSString stringWithFormat:@"%d",_languageId];
    return [[_scores objectForKey:key] objectForKey:@"scores"];
}

- (float)bestScore {
    NSString *key = [NSString stringWithFormat:@"%d",_languageId];
    NSDictionary *scoreStruct = [_scores objectForKey:key];
    if (scoreStruct == nil) {
        return 0.0;
    } else {
        return [[scoreStruct objectForKey:@"maxscore"] floatValue];
    }
}

- (NSDictionary *)defaultClassifier {
    NSString *filePath = [[NSBundle mainBundle]
                          pathForResource:@"global_proto.json" ofType:@""];
    NSData *data = [[NSData alloc] initWithContentsOfFile:filePath];
    NSError *error;
    return [NSJSONSerialization JSONObjectWithData:data
                                           options:kNilOptions
                                             error:&error];
}

- (void)addSession:(NSDictionary *)jsonData {
    [_sessions addObject:jsonData];
}

// Build cache
- (void)switchToLanguageId:(int)langId {
    _languageId = langId;
    NSString *langIdStr = [NSString stringWithFormat:@"%d",_languageId];
    NSDictionary *jsonObj = [_classifiers objectForKey:langIdStr];
    
    _labelArray = [[[[GlobalStorage sharedInstance] languages]
                    objectForKey:langIdStr] objectForKey:@"characters"];
  
    if (jsonObj == nil) {
        _dtwClassifier = nil;
    } else {
        _exampleSet = [[ExampleSet alloc] initWithJSONObject:jsonObj];
        _dtwClassifier = nil;

    }
}

- (int)classifierId {
    return [_exampleSet classifier_id];
}

- (NSString *)languageName {
    GlobalStorage *gs = [GlobalStorage sharedInstance];
    NSDictionary *langInfo = [[gs languages]
                              objectForKey:[NSString stringWithFormat:@"%d",_languageId]];
    return [langInfo objectForKey:@"name"];
}

- (void)updateClassifier:(NSDictionary *)c forLanguage:(int)languageId {
    NSString *langId = [NSString stringWithFormat:@"%d",languageId];
    [_classifiers setObject:c forKey:langId];
}

@end
