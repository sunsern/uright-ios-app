//
//  BFClassifier.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 12/8/12.
//
//

#import <Foundation/Foundation.h>
#import "URJSONSerializable.h"

@class InkPoint;

@protocol BFClassifierDelegate
- (void)thresholdReached:(InkPoint *)point;
- (void)updateScore:(float)targetProb;
@end

@interface BFClassifier : NSObject <URJSONSerializable>

@property (readwrite) int beamCount;
@property (readwrite) float targetThreshold;
@property (nonatomic,strong) NSArray *prototypes;
@property (nonatomic,copy) NSString *targetLabel;
@property (nonatomic,weak) id<BFClassifierDelegate> delegate;

- (id)initWithPrototypes:(NSArray *)prototypes;

- (void)reset;

- (void)addPoint:(InkPoint *)point;

- (NSDictionary *)finalLikelihood;

- (NSDictionary *)likelihood;

@end
