//
//  BFClassifier.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 12/8/12.
//
//

#import <Foundation/Foundation.h>
#import "JCSuperPriorityQueue.h"

@class InkPoint;

@protocol BFClassifierDelegate
- (void)thresholdReached:(InkPoint *)point;
- (void)updateScore:(float)targetProb;
@end

@interface BFClassifier : NSObject

@property (nonatomic,copy) NSString *targetLabel;
@property (readwrite) int beamCount;
@property (readwrite) float targetThreshold;
@property (readonly) int classifierId;
@property (nonatomic,weak) id<BFClassifierDelegate> delegate;

- (id)initWithJSONObject:(id)jsonObj;
- (id)toJSONObject;

- (void)reset;
- (void)addPoint:(InkPoint *)point;

- (NSDictionary *)finalLikelihood;
- (NSDictionary *)likelihood;

@end
