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

@protocol PredictionReadyDelegate
- (void)updateUI:(float)v;
@end


@interface StateData : NSObject
@property (readwrite) double alpha;
@property (readwrite) int prototypeIdx;
@property (readwrite) int stateIdx;
@end

@interface PrototypeData : NSObject
@property (nonatomic,copy) NSString *label;
@property (nonatomic,strong) NSArray *pointArray;
@property (readwrite) double prior;
@end


@interface DtwOnlineClassifier : NSObject  {
    JCSuperPriorityQueue *_beamPQ;
    NSArray *_prototypes;
    InkPoint *_sumSqPoint;
    InkPoint *_sumPoint;
    InkPoint *_prevPoint;
    int _pointCount;
    double _start_time;
    double _last_point_time;
    NSMutableDictionary *_likelihood;
    dispatch_queue_t _serialQueue;
}

@property (copy) NSString *targetLabel;
@property (readwrite) int beamCount;
@property (nonatomic,weak) id<PredictionReadyDelegate> delegate;

- (id)initWithExampleSet:(ExampleSet *)exSet;

- (void)resetClassifier;

- (void)addPointWithX:(float) x y:(float)y t:(double)t;

- (void)addPenUp;

- (NSString *)bestPrediction;

- (NSDictionary *)likelihood;

@end
