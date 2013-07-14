//
//  SessionData.m
//  Handwriting
//
//  Created by Sunsern Cheamanunkul on 4/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//  This is for storing data collected during a session

#import "SessionData.h"
#import "RoundData.h"

@implementation SessionData

- (id)init {
    self = [super init];
    if (self) {
        _userId = -1;
        _languageId = -1;
        _modeId = -1;
        _classifierId = -1;
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
        _userId = [jsonObj[@"userId"] intValue];
        _languageId = [jsonObj[@"languageId"] intValue];
        _modeId = [jsonObj[@"modeId"] intValue];
        _classifierId = [jsonObj[@"classifierId"] intValue];
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
    jsonObj[@"version"] = @"uRight3";
    jsonObj[@"userId"] = @(_userId);
    jsonObj[@"languageId"] = @(_languageId);
    jsonObj[@"modeId"] = @(_modeId);
    jsonObj[@"classifierId"] = @(_classifierId);
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
