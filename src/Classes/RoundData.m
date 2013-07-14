//
//  RoundData.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/13/13.
//
//

#import "RoundData.h"

#import "InkCharacter.h"
#import "ClassificationResult.h"

@implementation RoundData

- (id)initWithJSONObject:(id)jsonObj {
    self = [super init];
    if (self) {
        _startTime = [jsonObj[@"startTime"] doubleValue];
        _firstPendownTime = [jsonObj[@"firstPendownTime"] doubleValue];
        _lastPenupTime = [jsonObj[@"lastPenupTime"] doubleValue];
        _score = [jsonObj[@"score"] floatValue];
        _label = [jsonObj[@"label"] copy];
        _ink = [[InkCharacter alloc] initWithJSONObject:jsonObj[@"ink"]];
        _result = [[ClassificationResult alloc]
                   initWithJSONObject:jsonObj[@"result"]];
    }
    return self;
}

- (id)toJSONObject {
    NSMutableDictionary *jsonObj = [[NSMutableDictionary alloc] init];
    jsonObj[@"startTime"] = @(_startTime);
    jsonObj[@"firstPendownTime"] = @(_firstPendownTime);
    jsonObj[@"lastPenupTime"] = @(_lastPenupTime);
    jsonObj[@"score"] = @(_score);
    if (_label) {
        jsonObj[@"label"] = _label;
    }
    if (_ink) {
        jsonObj[@"ink"] = [_ink toJSONObject];
    }
    if (_result) {
        jsonObj[@"result"] = [_result toJSONObject];
    }
    return jsonObj;
}


@end
