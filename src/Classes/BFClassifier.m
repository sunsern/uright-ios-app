//
//  DtwOnlineClassifier.m
//  uRight2
//
//  Created by Sunsern Cheamanunkul on 12/8/12.
//
//

#import "BFClassifier.h"
#import "ExampleSet.h"
#import "InkExample.h"
#import "InkPoint.h"
#import "BFPrototype.h"

#define kAlpha 0.5
#define kSkip 3
#define kQueueThreshold -10.0 

#define HASHKEY(x,y) ([NSNumber numberWithInteger:x*1000 + y])

float logsumexp(float x,float y) {
    float temp;
    temp = MAX(x,y);
    return temp + log(exp(x-temp) + exp(y-temp));
}

@interface StateData : NSObject
@property (readwrite) float alpha;
@property (readwrite) int prototypeIdx;
@property (readwrite) int stateIdx;
@end

@implementation StateData
@end

@interface CacheData : NSObject
@property (readwrite) float cost;
@property (nonatomic, strong) StateData *state;
@end

@implementation CacheData
@end

@implementation BFClassifier  {
    JCSuperPriorityQueue *_beamPQ;
    NSArray *_prototypes;
    InkPoint *_sumSqPoint;
    InkPoint *_sumPoint;
    InkPoint *_prevPoint;
    int _pointCount;
    NSMutableDictionary *_likelihood;
    NSMutableDictionary *_finalLikelihood;
    dispatch_queue_t _serialQueue;
    NSMutableDictionary *_cacheDict;
}

- (id)initWithExampleSet:(ExampleSet *)exSet {
    self = [super init];
    if (self) {
        _serialQueue = dispatch_queue_create("uRight.DtwOnlineClassifier", NULL);
        NSDictionary *dict = [exSet examples];
        NSArray *labelArray = [dict allKeys];
        NSMutableArray *prototypes = [[NSMutableArray alloc] init];
        for (int i=0; i < [labelArray count];i++) {
            NSString *label = [labelArray objectAtIndex:i];
            NSArray *examples = [dict objectForKey:label];
            NSLog(@"%@ = %d", label, [examples count]);
            for (InkExample *inkEx in examples) {
                BFPrototype *pData = [[BFPrototype alloc] initWithInkExample:inkEx
                                                                       prior:0.0];
                [prototypes addObject:pData];
            }
        }
        _beamCount = 500;
        _prototypes = prototypes;
        _beamPQ = [[JCSuperPriorityQueue alloc] init];
        _likelihood = [[NSMutableDictionary alloc] init];
        _finalLikelihood = [[NSMutableDictionary alloc] init];
        _cacheDict = [[NSMutableDictionary alloc] init];
        [self reset];
    }
    return self;
}


- (void)dealloc {
    dispatch_release(_serialQueue);
}


// sync method
- (void)reset {
    dispatch_sync(_serialQueue, ^{
        NSLog(@"Reset classifier");
        [_beamPQ clear];
        for (int i=0; i<[_prototypes count];i++) {
            StateData *s = [[StateData alloc] init];
            s.alpha = ((BFPrototype *)_prototypes[i]).prior;
            s.prototypeIdx = i;
            s.stateIdx = -1;
            [_beamPQ addObject:s value:s.alpha];
        }
        _pointCount = 0;
        _sumPoint = [[InkPoint alloc] init];
        _sumSqPoint = [[InkPoint alloc] init];
        _prevPoint = nil;
    });
}


+ (float)computeCostInkPoint:(InkPoint *)a
                          to:(InkPoint *)b
{
    if (a.penup && b.penup) {
        return 0.0;
    } else if (a.penup || b.penup) {
        return -10.0;
    }
    else {
        float d_dir = [InkPoint directionDistanceFrom:a to:b];
        float d_loc = [InkPoint locationDistanceFrom:a to:b];
        float d_final = kAlpha*d_loc + (1.0 - kAlpha)*d_dir;
        
        return -d_final;
    }
}

- (float)setCostForStateIdx:(int)stateIdx
               prototypeIdx:(int)prototypeIdx
                  extraCost:(float)extraCost
                 inputPoint:(InkPoint *)inputPoint
                      pData:(BFPrototype *)pData {
    // Create a hash key
    id <NSCopying> key = HASHKEY(prototypeIdx,stateIdx);
    
    // Cached data
    CacheData *data = _cacheDict[key];
    float cost = 0;
    if (data == nil) {
        cost = [BFClassifier computeCostInkPoint:(pData.pointArray)[stateIdx]
                                              to:inputPoint];
        StateData *state = [[StateData alloc] init];
        state.prototypeIdx = prototypeIdx;
        state.stateIdx = stateIdx;
        state.alpha = extraCost + cost;
        CacheData *newData = [[CacheData alloc] init];
        newData.cost = cost;
        newData.state = state;
        _cacheDict[key] = newData;
    } else {
        cost = data.cost;
        StateData *existingState = data.state;
        existingState.alpha = logsumexp(existingState.alpha,
                                        extraCost + cost);
    }
    return extraCost + cost;
}

// Async
- (void)addPoint:(InkPoint *)point {
    
    if (!point.penup && _prevPoint &&
        [InkPoint locationDistanceFrom:point to:_prevPoint] < 0.0002) {
        NSLog(@"DENIED");
        return;
    }
    
    dispatch_async(_serialQueue, ^{
        
        if (!point.penup && _prevPoint) {
            float dx = point.x - _prevPoint.x;
            float dy = point.y - _prevPoint.y;
            float norm = sqrt(dx*dx+dy*dy);
            point.dx = dx / MAX(norm,1e-5);
            point.dy = dy / MAX(norm,1e-5);
        }
        
        //[_cacheDict removeAllObjects];
        _cacheDict = [[NSMutableDictionary alloc] init];
        
        StateData *state = [_beamPQ pop];
        int c = 0;
        while (state != nil && c < _beamCount) {
            //NSLog(@"working state %d, %d %f",[state prototypeIdx],  [state stateIdx], [state alpha]);
            float alpha = [state alpha];
            //NSLog(@"%0.3f",alpha);
            BFPrototype *pData = _prototypes[state.prototypeIdx];
            // Case 1: stay
            if ([state stateIdx] >= 0) {
                [self setCostForStateIdx:state.stateIdx
                            prototypeIdx:state.prototypeIdx
                               extraCost:alpha
                              inputPoint:point
                                   pData:pData];
            }
            // Case 2: move forward
            for (int k = [state stateIdx]+1;
                 k < MIN([state stateIdx]+kSkip, [pData length]); k++) {
                alpha = [self setCostForStateIdx:k
                                    prototypeIdx:state.prototypeIdx
                                       extraCost:alpha
                                      inputPoint:point
                                           pData:pData];
            }
            state = [_beamPQ pop];
            c++;
        }
        
        // Clear the queue
        [_beamPQ clear];
        
        // pack the new states to the PQ
        [_likelihood removeAllObjects];
        [_finalLikelihood removeAllObjects];
        
        // try normalize
        float sum_like = -FLT_MAX;
        for (id <NSCopying> key in [_cacheDict allKeys]) {
            CacheData *cache = [_cacheDict objectForKey:key];
            StateData *s = cache.state;
            sum_like = logsumexp(sum_like, s.alpha);
        }
        
        for (id <NSCopying> key in [_cacheDict allKeys]) {
            CacheData *cache = [_cacheDict objectForKey:key];
            StateData *s = cache.state;
            // perform normalization
            s.alpha = s.alpha - sum_like;
            // insert the state to PQ
            if (s.alpha > kQueueThreshold) {
                [_beamPQ addObject:s value:s.alpha];
            }
            
            // update likelihood
            NSString *label = [_prototypes[s.prototypeIdx] label];
            NSNumber *existing = _likelihood[label];
            if (existing != nil) {
                _likelihood[label] = @(logsumexp([existing floatValue], s.alpha));
            } else {
                _likelihood[label] = @(s.alpha);
            }
            
            // update final likelihood
            if (s.stateIdx == [_prototypes[s.prototypeIdx] length] - 1) {
                _finalLikelihood[label] = @(s.alpha);
            }
        }
        
        // Likelihood normalization
        sum_like = -FLT_MAX;
        for (NSString *label in [_likelihood allKeys]) {
            float x = [_likelihood[label] floatValue];
            sum_like = logsumexp(sum_like, x);
        }
        for (NSString *label in [_likelihood allKeys]) {
            _likelihood[label] = @(exp([_likelihood[label] floatValue] - sum_like));
        }
        
        sum_like = -FLT_MAX;
        for (NSString *label in [_finalLikelihood allKeys]) {
            float x = [_finalLikelihood[label] floatValue];
            sum_like = logsumexp(sum_like, x);
        }
        for (NSString *label in [_finalLikelihood allKeys]) {
            _finalLikelihood[label] = @(exp([_finalLikelihood[label] floatValue] - sum_like));
        }
        
        float p = 1.0 / [_likelihood[_targetLabel] floatValue];
        if (log2(p) < 1.0) {
            [_delegate thresholdReached:point];
        }
        
        if (point.penup) {
            NSLog(@"%@", _finalLikelihood);
            [_delegate updateScore:[_finalLikelihood[_targetLabel] floatValue]];
            _prevPoint = nil;
        } else {
            _prevPoint = [[InkPoint alloc] initWithInkPoint:point];
        }
    });
}

- (NSDictionary *)likelihood {
    return _likelihood;
}

- (NSDictionary *)finalLikelihood {
    return _finalLikelihood;
}


@end
