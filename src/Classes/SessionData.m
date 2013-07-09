//
//  SessionData.m
//  Handwriting
//
//  Created by Sunsern Cheamanunkul on 4/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//  This is for storing data collected during a session

#import "SessionData.h"

#import "ClassificationResult.h"
#import "InkExample.h"
#import "InkCharacter.h"

@implementation SessionData

- (id)initWithUserId:(int)uid languageId:(int)lid modeId:(int)mid classifierId:(int)cid {
    self = [super init];
    if (self) {
        _userId = uid;
        _languageId = lid;
        _modeId = mid;
        _classifierId = cid;
        _totalMultiStrokes = 0;
        _totalPauseTime = 0;
    }
    return self;
}

- (void)beginSession {
    _packedExampleArray = [[NSMutableArray alloc] init];
    _startTime = [NSDate timeIntervalSinceReferenceDate];
    _bps = 0;
}

- (void)endSession {
    _endTime = [NSDate timeIntervalSinceReferenceDate];
}

- (void)addInkExample:(InkExample *)inkExample
    classificationResult:(ClassificationResult *)result
                 attempt:(int)attempt {
    // compute pause time
    double pt = [[inkExample inkCharacter] averagePauseTime];
    if (pt > 0) {
        _totalPauseTime += pt;
        _totalMultiStrokes++;
    }
    
    NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
    if (inkExample != nil) {
        [data setObject:[inkExample toJSONObject]
                 forKey:@"example"];
    }
    if (result != nil) {
        [data setObject:[result toJSONObject] 
                 forKey:@"result"];
    }
    [data setObject:[NSNumber numberWithInt:attempt] forKey:@"attempt"];
    [_packedExampleArray addObject:data];
}

- (id)initWithJSONObject:(NSDictionary *)jsonObj {
    self = [super init];
    if (self && jsonObj) {
        _packedExampleArray = [[NSMutableArray alloc] initWithArray:[jsonObj objectForKey:@"packedExampleArray"]];
        _startTime = [[jsonObj objectForKey:@"startTime"] doubleValue];
        _endTime = [[jsonObj objectForKey:@"endTime"] doubleValue];
        _bps = [[jsonObj objectForKey:@"bps"] floatValue];
        _modeId = [[jsonObj objectForKey:@"modeId"] intValue];
        _userId = [[jsonObj objectForKey:@"userId"] intValue];
        _languageId = [[jsonObj objectForKey:@"languageId"] intValue];
        _classifierId = [[jsonObj objectForKey:@"classifierId"] intValue];
    }
    return self;
}

- (NSData *)examplesJSONData {
    NSError *error;
    return [NSJSONSerialization dataWithJSONObject:_packedExampleArray
                                           options:kNilOptions
                                             error:&error];
}

- (NSDictionary *)toJSONObject {
    return @{@"packedExampleArray":_packedExampleArray,
             @"startTime":@(_startTime),
             @"endTime":@(_endTime),
             @"bps":@(_bps),
             @"modeId":@(_modeId),
             @"userId":@(_userId),
             @"languageId":@(_languageId),
             @"classifierId":@(_classifierId)};
}

- (int)examplesCount {
    return [_packedExampleArray count];
}

- (double)averagePauseTime {
    if (_totalMultiStrokes == 0) {
        return 0;
    } else {
        return (_totalPauseTime / _totalMultiStrokes);
    }
}

@end
