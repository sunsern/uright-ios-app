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

- (NSDictionary *)toJSONObject {
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
