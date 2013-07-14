//
//  ClassificationResult.m
//  Handwriting
//
//  Created by Sunsern Cheamanunkul on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ClassificationResult.h"

@implementation ClassificationResult 

- (id)initWithJSONObject:(id)jsonObj {
    self = [super init];
    if (self) {
        _resultDictionary = [[NSDictionary alloc] initWithDictionary:jsonObj];
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _resultDictionary = [[NSDictionary alloc] initWithDictionary:dict];
    }
    return self;
}

- (NSString *)predictionByRanking:(int)rank {
    NSArray *sortedLabels = [_resultDictionary
                             keysSortedByValueUsingSelector:@selector(compare:)];
    return [sortedLabels objectAtIndex:rank];
}

- (double)scoreByRanking:(int)rank {
    NSArray *sortedScores = [[_resultDictionary allValues]
                             sortedArrayUsingSelector:@selector(compare:)];
    return [[sortedScores objectAtIndex:rank] doubleValue];
}

- (double)scoreByLabel:(NSString *)label {
    return [[_resultDictionary objectForKey:label] doubleValue];
}

- (id)toJSONObject {
    return _resultDictionary;
}

@end
