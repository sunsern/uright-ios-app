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

#define HASHKEY(x,y) ([NSNumber numberWithInteger:x*1000 + y])

double logsumexp(double x,double y) {
    double temp;
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
        _beamCount = 200;
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
        return -100.0;
    }
    else {
        double d_dir = [InkPoint directionDistanceFrom:a to:b];
        double d_loc = [InkPoint locationDistanceFrom:a to:b];
        
        double d_dir_final = d_dir;
        double d_loc_final = d_loc;
        
        double d_final = kAlpha*d_loc_final + (1.0 - kAlpha)*d_dir_final;
        
        d_final = -d_final;
    
        return d_final;
    }  
}

- (double)setCostForStateIdx:(int)stateIdx
                prototypeIdx:(int)prototypeIdx
                   extraCost:(float)extraCost
                  inputPoint:(InkPoint *)inputPoint
                       pData:(BFPrototype *)pData {
    
    // Extract the point
    InkPoint *p = [[pData pointArray] objectAtIndex:stateIdx];
    
    // Create a hash key
    id <NSCopying> key = HASHKEY(prototypeIdx,stateIdx);
    
    // Cached data
    NSArray *hashedData = _cacheDict[key];
    float d = 0;
    if (hashedData == nil) {
        d = [BFClassifier computeCostInkPoint:p to:inputPoint];
        StateData *state = [[StateData alloc] init];
        state.prototypeIdx = prototypeIdx;
        state.stateIdx = stateIdx;
        state.alpha = extraCost + d;
        _cacheDict[key] = @[@(d), state];
    } else {
        d = [hashedData[0] floatValue];
        StateData *existingState = hashedData[1];
        existingState.alpha = logsumexp(existingState.alpha,
                                        extraCost + d);
        _cacheDict[key] = @[@(d), existingState];
    }
    return extraCost + d;
}

// Async
- (void)addPoint:(InkPoint *)point {
    dispatch_async(_serialQueue, ^{
        [_cacheDict removeAllObjects];
        
        StateData *state = [_beamPQ pop];
        int c = 0;
        while (state != nil && c < _beamCount) {
            //NSLog(@"working state %d, %d %f",[state prototypeIdx],  [state stateIdx], [state alpha]);
            double alpha = [state alpha];
            //NSLog(@"%0.3f",alpha);
            BFPrototype *pData = [_prototypes objectAtIndex:[state prototypeIdx]];
            // Case 1: stay
            if ([state stateIdx] >= 0) {
                [self setCostForStateIdx:[state stateIdx]
                            prototypeIdx:[state prototypeIdx]
                               extraCost:alpha
                              inputPoint:point
                                   pData:pData];
            }
            // Case 2: move forward
            for (int k = [state stateIdx]+1;
                 k < MIN([state stateIdx]+kSkip,[[pData pointArray] count]); k++) {
                alpha = [self setCostForStateIdx:k
                                    prototypeIdx:[state prototypeIdx]
                                       extraCost:alpha
                                      inputPoint:point
                                           pData:pData];
            }
            state = [_beamPQ pop];
            c++;
        }
        
        [_beamPQ clear];
        
        // pack the new states to the PQ
        [_likelihood removeAllObjects];
        [_finalLikelihood removeAllObjects];
        
        for (id <NSCopying> key in [_cacheDict allKeys]) {
            NSArray *cache = [_cacheDict objectForKey:key];
            StateData *s = cache[1];
            // insert the state to PQ
            if ([s alpha] > -100) {
                [_beamPQ addObject:s value:[s alpha]];
                
                // update likelihood
                NSString *label = [[_prototypes objectAtIndex:[s prototypeIdx]] label];
                NSNumber *existing = [_likelihood objectForKey:label];
                if (existing != nil) {
                    [_likelihood setObject:@(logsumexp([existing doubleValue], [s alpha]))
                                    forKey:label];
                } else {
                    [_likelihood setObject:@([s alpha]) forKey:label];
                }
                
                // update final likelihood
                if ([s stateIdx] == [((BFPrototype *)_prototypes[s.prototypeIdx]).pointArray
                                     count] - 1) {
                    NSString *label = [[_prototypes objectAtIndex:[s prototypeIdx]] label];
                    [_finalLikelihood setObject:@([s alpha]) forKey:label];
                }
            }
        }
        
        double sum_like = -DBL_MAX;
        for (NSString *label in [_likelihood allKeys]) {
            double x = [_likelihood[label] doubleValue];
            sum_like = logsumexp(sum_like, x);
        }
        for (NSString *label in [_likelihood allKeys]) {
            _likelihood[label] = @(exp([_likelihood[label] doubleValue] - sum_like));
        }
        
        sum_like = -DBL_MAX;
        for (NSString *label in [_finalLikelihood allKeys]) {
            double x = [_finalLikelihood[label] doubleValue];
            sum_like = logsumexp(sum_like, x); 
        }
        for (NSString *label in [_finalLikelihood allKeys]) {
            _finalLikelihood[label] = @(exp([_finalLikelihood[label] doubleValue] - sum_like));
        }
        
        float p = 1.0 / [_likelihood[_targetLabel] floatValue];
        if (log2(p) < 1.0) {
            [_delegate thresholdReached];
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
