//
//  SessionData.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 4/12/12.
//
//  This is for storing data collected during a session

#import "SessionData.h"
#import "RoundData.h"

@implementation SessionData

- (id)init {
    self = [super init];
    if (self) {
        _userID = -1;
        _languageID = -1;
        _modeID = -1;
        _classifierID = -1;
        _bps = 0.0;
        _totalScore = 0.0;
        _totalTime = 0.0;
        _rounds = [[NSMutableArray alloc] init];
    }
    return self;
}

- (id)initWithJSONObject:(id)jsonObj {
    self = [super init];
    if (self) {
        _userID = [jsonObj[@"userID"] intValue];
        _languageID = [jsonObj[@"languageID"] intValue];
        _modeID = [jsonObj[@"modeID"] intValue];
        _classifierID = [jsonObj[@"classifierID"] intValue];
        _bps = [jsonObj[@"bps"] floatValue];
        _totalScore = [jsonObj[@"totalScore"] floatValue];
        _totalTime = [jsonObj[@"totalTime"] floatValue];
        _rounds = [[NSMutableArray alloc] init];
        for (id each_round in jsonObj[@"rounds"]) {
            RoundData *round = [[RoundData alloc]initWithJSONObject:each_round];
            [_rounds addObject:round];
        }
    }
    return self;
}

- (NSDictionary *)toJSONObject {
    NSMutableDictionary *jsonObj = [[NSMutableDictionary alloc] init];
    jsonObj[@"version"] = kURAppName;
    jsonObj[@"userID"] = @(_userID);
    jsonObj[@"languageID"] = @(_languageID);
    jsonObj[@"modeID"] = @(_modeID);
    jsonObj[@"classifierID"] = @(_classifierID);
    jsonObj[@"bps"] = @(_bps);
    jsonObj[@"totalTime"] = @(_totalTime);
    jsonObj[@"totalScore"] = @(_totalScore);
    if (_rounds) {
        NSMutableArray *roundJSON = [[NSMutableArray alloc] init];
        for (RoundData *round in _rounds) {
            [roundJSON addObject:[round toJSONObject]];
        }
        jsonObj[@"rounds"] = roundJSON;
    }
    return jsonObj;
}

- (void)addRound:(RoundData *)round {
    [_rounds addObject:round];
}

@end
