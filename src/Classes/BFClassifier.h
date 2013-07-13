//
//  DtwOnlineClassifier.h
//  uRight2
//
//  Created by Sunsern Cheamanunkul on 12/8/12.
//
//

#import <Foundation/Foundation.h>
#import "JCSuperPriorityQueue.h"

@class ExampleSet;
@class InkPoint;

@protocol BFClassifierDelegate
- (void)thresholdReached:(InkPoint *)point;
- (void)updateScore:(float)v;
@end


@interface BFClassifier : NSObject

@property (readwrite) int beamCount;
@property (copy) NSString *targetLabel;
@property (readwrite) float targetThreshold;
@property (nonatomic,weak) id<BFClassifierDelegate> delegate;

- (id)initWithExampleSet:(ExampleSet *)exSet;

- (void)reset;

- (void)addPoint:(InkPoint *)point;

- (NSDictionary *)finalLikelihood;
- (NSDictionary *)likelihood;

@end
