//
//  ClassificationResult.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 4/13/12.
//

#import "ClassificationResult.h"

@implementation ClassificationResult 

- (id)initWithJSONObject:(id)jsonObj {
    self = [super init];
    if (self) {
        _scores = [[NSDictionary alloc] initWithDictionary:jsonObj];
    }
    return self;
}

- (id)toJSONObject {
    return _scores;
}

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        _scores = [[NSDictionary alloc] initWithDictionary:dict];
    }
    return self;
}

- (NSString *)predictionByRanking:(int)rank {
    NSArray *sortedLabels = [_scores
                             keysSortedByValueUsingSelector:@selector(compare:)];
    return [sortedLabels objectAtIndex:[sortedLabels count] - 1 - rank];
}

- (double)scoreByRanking:(int)rank {
    NSArray *sortedScores = [[_scores allValues]
                             sortedArrayUsingSelector:@selector(compare:)];
    return [[sortedScores objectAtIndex:rank] doubleValue];
}

- (double)scoreByLabel:(NSString *)label {
    return [[_scores objectForKey:label] doubleValue];
}

@end
