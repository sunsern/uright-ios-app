//
//  BFClassifier.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 12/8/12.
//
//

#import "BFClassifier.h"

#import "BFPrototype.h"
#import "InkPoint.h"
#import "InkCharacter.h"
#import "JCSuperPriorityQueue.h"

// Default DTW config
#define kPenupPenalty 10.0
#define kAlpha 0.5
#define kSkip 3

// Deafult beam config
#define kQueueThreshold -10.0
#define kBeamWidth 800

// Online mode
#define kIgnoreAddpoint 0.01
#define kLikelihoodThreshold 1.0

// Batch mode
#define kSmoothingFactor 20


#define HASHKEY(x,y) ([SimpleHashKey hashkey:((x)*1000+(y))])
#define logsumexp(x,y) ((x)<(y) ? y+log(1+exp(x-y)) : x+log(1+exp(y-x)))

///////////////////////

@interface SimpleHashKey : NSObject <NSCopying>
@property int key;
+ (id)hashkey:(int)key;
@end

@implementation SimpleHashKey
+ (id)hashkey:(int)key {
    id obj = [[[self class] alloc] init];
    [obj setKey:key];
    return obj;
}
- (id)copyWithZone:(NSZone *)zone {
    id copy = [[[self class] allocWithZone:zone] init];
    if (copy) {
        [copy setKey:_key];
    }
    return copy;
}
- (BOOL)isEqual:(id)object {
    SimpleHashKey *other = (SimpleHashKey *)object;
    return _key == other.key;
}
- (NSUInteger)hash {
    return _key;
}
@end

/////////////////////

@interface StateData : NSObject
@property (readwrite) float alpha;
@property (readwrite) int prototypeIdx;
@property (readwrite) int stateIdx;
@end

@implementation StateData
@end

/////////////////////


@interface CacheData : NSObject
@property (readwrite) float cost;
@property (readwrite) BOOL valid;
@property (nonatomic, strong) StateData *state;
@end

@implementation CacheData
@end

/////////////////////

@implementation BFClassifier  {
    dispatch_queue_t _serialQueue;
    JCSuperPriorityQueue *_beamPQ;
    InkPoint *_prevPoint;
    NSMutableDictionary *_likelihood;
    NSMutableDictionary *_posterior;
    NSMutableDictionary *_cacheDict;
    NSMutableArray *_points;
    BOOL _thresholdReached;
    BOOL _earlyStopEnabled;
    BOOL _batchMode;
}

- (id)init {
    self = [super init];
    if (self) {
        // create a queue if not yet
        _serialQueue = dispatch_queue_create("uRight3.BFClassifier", NULL);
        dispatch_set_target_queue(_serialQueue,
                                  dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0));
        _beamCount = kBeamWidth;
        _targetThreshold = kLikelihoodThreshold;
        _posterior = [[NSMutableDictionary alloc] init];
        _thresholdReached = NO;
    }
    return self;
}

- (id)initWithPrototypes:(NSArray *)prototypes mode:(BFClassifierMode)mode {
    self = [self init];
    if (mode == BFClassifierModeBatch) {
        _batchMode = YES;
        _points = [[NSMutableArray alloc] init];
    }
    else if (mode == BFClassifierModeEarlyPenup) {
        _batchMode = NO;
        _earlyStopEnabled = YES;
        _beamPQ = [[JCSuperPriorityQueue alloc] init];
        _cacheDict = [[NSMutableDictionary alloc] initWithCapacity:kBeamWidth * 2];
        _likelihood = [[NSMutableDictionary alloc] init];
        
    }
    else if (mode == BFClassifierModeOnline) {
        _batchMode = NO;
        _earlyStopEnabled = NO;
        _beamPQ = [[JCSuperPriorityQueue alloc] init];
        _cacheDict = [[NSMutableDictionary alloc] initWithCapacity:kBeamWidth * 2];
    }
    else {
        // invalid mode error
        return nil;
    }
    _prototypes = [[NSArray alloc] initWithArray:prototypes];
    return self;
}

// sync method
- (void)reset {
    dispatch_sync(_serialQueue, ^{
        if (_batchMode) {
            [_points removeAllObjects];
            _prevPoint = nil;
        }
        else {
            //DEBUG_PRINT(@"Reset classifier");
            [_beamPQ clear];
            for (int i=0; i<[_prototypes count];i++) {
                StateData *state = [[StateData alloc] init];
                state.alpha = log(((BFPrototype *)_prototypes[i]).prior);
                state.prototypeIdx = i;
                state.stateIdx = -1;
                [_beamPQ addObject:state value:state.alpha];
            }
            
            // Make a new cache
            _cacheDict = [[NSMutableDictionary alloc] initWithCapacity:_beamCount*2];
            _thresholdReached = NO;
            _prevPoint = nil;
        }
    });
}


- (void)addPoint:(InkPoint *)point {
    
    // remove redundant points
    if (!point.penup && _prevPoint &&
        [InkPoint locationDistanceFrom:point to:_prevPoint] < kIgnoreAddpoint) {
        //NSLog(@"Point too close to the previous point, ignoring");
        return;
    }

    // Compute dx, dy
    if (!point.penup && _prevPoint) {
        float dx = point.x - _prevPoint.x;
        float dy = point.y - _prevPoint.y;
        float norm = sqrt(dx*dx+dy*dy);
        point.dx = dx / MAX(norm,1e-6);
        point.dy = dy / MAX(norm,1e-6);
    }
    
    if (_batchMode) {
        [_points addObject:point];
        if (point.penup) {
            dispatch_async(_serialQueue, ^{
                [self runBatch];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate updateScore:[_posterior[_targetLabel] floatValue]];
                });
            });
            _prevPoint = nil;
        }
        else {
            _prevPoint = [[InkPoint alloc] initWithInkPoint:point];
        }
    }
    else {
        dispatch_async(_serialQueue, ^{
            
            [self invalidateCacheData];
            StateData *state = [_beamPQ pop];
            
            int c = 0;
            while (state != nil && c < _beamCount) {
                float alpha = [state alpha];
                BFPrototype *pData = _prototypes[state.prototypeIdx];
                
                //////////////////////////////////////////
                // Early penup: Link penup to the end state
                // after threshold has been reached.
                //////////////////////////////////////////
                if (_earlyStopEnabled && point.penup && _thresholdReached &&
                    [pData.label isEqualToString:_targetLabel]) {
                    [self setCostForStateIdx:[pData length] - 1
                                prototypeIdx:state.prototypeIdx
                                   extraCost:alpha
                                  inputPoint:point
                                       pData:pData];
                }
                
                
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
            
            // Normalize live states
            float sum_like = -FLT_MAX;
            for (id key in _cacheDict) {
                CacheData *cache = _cacheDict[key];
                if (cache.valid) {
                    StateData *state = cache.state;
                    sum_like = logsumexp(sum_like, state.alpha);
                }
            }
            
            [_posterior removeAllObjects];
            
            if (_earlyStopEnabled) {
                [_likelihood removeAllObjects];
            }
            
            for (id key in _cacheDict) {
                CacheData *cache = _cacheDict[key];
                if (cache.valid) {
                    StateData *state = cache.state;
                    
                    // perform normalization
                    state.alpha = state.alpha - sum_like;
                    // insert the state to PQ
                    if (state.alpha > kQueueThreshold) {
                        [_beamPQ addObject:state value:state.alpha];
                    }
                    
                    // update likelihood
                    NSString *label = [_prototypes[state.prototypeIdx] label];
                    
                    if (_earlyStopEnabled) {
                        NSNumber *existing = _likelihood[label];
                        if (existing != nil) {
                            _likelihood[label] = @(logsumexp([existing floatValue], state.alpha));
                        } else {
                            _likelihood[label] = @(state.alpha);
                        }
                    }
                    
                    // update final likelihood
                    if (state.stateIdx == [_prototypes[state.prototypeIdx] length] - 1) {
                        _posterior[label] = @(state.alpha);
                    }
                }
            }
            
            // Likelihood normalization
            if (_earlyStopEnabled) {
                sum_like = -FLT_MAX;
                for (id key in _likelihood) {
                    sum_like = logsumexp(sum_like, [_likelihood[key] floatValue]);
                }
                for (id key in [_likelihood allKeys]) {
                    _likelihood[key] = @(exp([_likelihood[key]
                                              floatValue] - sum_like));
                }
                float p = [_likelihood[_targetLabel] floatValue];
                if (-log2f(p) < _targetThreshold) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_delegate thresholdReached:point];
                    });
                    _thresholdReached = YES;
                }
            }
            
            // Posterior normalization
            sum_like = -FLT_MAX;
            for (id key in _posterior) {
                sum_like = logsumexp(sum_like, [_posterior[key] floatValue]);
            }
            for (id key in [_posterior allKeys]) {
                _posterior[key] = @(exp([_posterior[key]
                                         floatValue] - sum_like));
            }
            
            if (point.penup) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate updateScore:[_posterior[_targetLabel] floatValue]];
                });
                _prevPoint = nil;
            } else {
                _prevPoint = [[InkPoint alloc] initWithInkPoint:point];
            }
        });
    }
}


- (NSDictionary *)posterior {
    return _posterior;
}

#pragma mark Online mode


- (void)invalidateCacheData {
    for (id key in _cacheDict) {
        CacheData *data = _cacheDict[key];
        data.valid = NO;
    }
}

+ (float)computeCostInkPoint:(InkPoint *)a
                          to:(InkPoint *)b
{
    if (a.penup && b.penup) {
        return 0.0;
    } else if (a.penup || b.penup) {
        return -kPenupPenalty;
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
        cost = [[self class] computeCostInkPoint:(pData.points)[stateIdx]
                                              to:inputPoint];
        StateData *state = [[StateData alloc] init];
        state.prototypeIdx = prototypeIdx;
        state.stateIdx = stateIdx;
        state.alpha = extraCost + cost;
        CacheData *newData = [[CacheData alloc] init];
        newData.cost = cost;
        newData.state = state;
        newData.valid = YES;
        _cacheDict[key] = newData;
    } else if (!data.valid) {
        cost = [[self class] computeCostInkPoint:(pData.points)[stateIdx]
                                              to:inputPoint];
        StateData *state = data.state;
        state.prototypeIdx = prototypeIdx;
        state.stateIdx = stateIdx;
        state.alpha = extraCost + cost;
        data.cost = cost;
        data.state = state;
        data.valid = YES;
    } else {
        cost = data.cost;
        StateData *existingState = data.state;
        existingState.alpha = logsumexp(existingState.alpha,
                                        extraCost + cost);
    }
    return extraCost + cost;
}

#pragma mark Batch mode

+ (float)computeDtwDistanceFromArray:(NSArray *)sourcePointArray
                             toArray:(NSArray *)targetPointArray {
    
	int n = [sourcePointArray count];
	int m = [targetPointArray count];
    
    if (n == 0 || m == 0) {
        return FLT_MAX;
    }
    
    // compute distance array
    float locationDistance[n][m];
    float directionDistance[n][m];
    float sumLocationDistance = 0;
    float sumLocationDistanceSq = 0;
    float sumDirectionDistance = 0;
    float sumDirectionDistanceSq = 0;
    int numPairs = 0;
    
    for (int i=0; i<n; i++) {
        InkPoint *p1 = [sourcePointArray objectAtIndex:i];
        for (int j=0; j<m; j++) {
            InkPoint *p2 = [targetPointArray objectAtIndex:j];
            if (p1.penup && p2.penup) {
                locationDistance[i][j] = 0;
                directionDistance[i][j] = 0;
            } else if (p1.penup || p2.penup) {
                locationDistance[i][j] = -1;
                directionDistance[i][j] = -1;
            }  else {
                locationDistance[i][j] = [InkPoint locationDistanceFrom:p1 to:p2];
                directionDistance[i][j] = [InkPoint directionDistanceFrom:p1 to:p2];
                sumLocationDistance += locationDistance[i][j];
                sumLocationDistanceSq += powf(locationDistance[i][j],2);
                sumDirectionDistance += directionDistance[i][j];
                sumDirectionDistanceSq += powf(directionDistance[i][j],2);
                numPairs++;
            }
		}
	}
    
    float locationDistanceMean = sumLocationDistance / numPairs;
    float locationDistanceVariance = (sumLocationDistanceSq / numPairs -
                                       locationDistanceMean * locationDistanceMean);
    float locationDistanceStd = sqrt(locationDistanceVariance);
    
    float directionDistanceMean = sumDirectionDistance / numPairs;
    float directionDistanceVariance = (sumDirectionDistanceSq / numPairs -
                                        directionDistanceMean * directionDistanceMean);
    float directionDistanceStd = sqrt(directionDistanceVariance);
    
    float penupPenalty = kPenupPenalty * (locationDistanceStd * kAlpha +
                                          directionDistanceStd * (1.0 - kAlpha));
    
    float dtw[n][m];
    int pathlength[n][m];
    
	dtw[0][0] = 0;
	pathlength[0][0] = 0;
    
    InkPoint *i0 = [sourcePointArray objectAtIndex:0];
    InkPoint *j0 = [targetPointArray objectAtIndex:0];
	for (int i=1; i<n; i++) {
        float d = 0;
        InkPoint *p1 = [sourcePointArray objectAtIndex:i];
        if (p1.penup && j0.penup) {
            d = 0;
        } else if (p1.penup || j0.penup) {
            d = penupPenalty;
        } else {
            d = ((locationDistance[i][0] / locationDistanceStd) * kAlpha +
                 (directionDistance[i][0] / directionDistanceStd) * (1.0 - kAlpha));
        }
		dtw[i][0] = dtw[i-1][0] + d;
        pathlength[i][0] = pathlength[i-1][0] + 1;
	}
	
	for (int j=1; j<m; j++) {
        float d = 0;
        InkPoint *p2 = [targetPointArray objectAtIndex:j];
        if (i0.penup && p2.penup) {
            d = 0;
        } else if (i0.penup || p2.penup) {
            d = penupPenalty;
        } else {
            d = ((locationDistance[0][j] / locationDistanceStd) * kAlpha +
                 (directionDistance[0][j] / directionDistanceStd) * (1.0 - kAlpha));
        }
		dtw[0][j] = dtw[0][j-1] + d;
        pathlength[0][j] = pathlength[0][j-1] + 1;
	}
    
	for (int i=1; i<n; i++) {
        InkPoint *p1 = [sourcePointArray objectAtIndex:i];
		for (int j=1; j<m; j++) {
            double d = 0;
            InkPoint *p2 = [targetPointArray objectAtIndex:j];
            if (p1.penup && p2.penup) {
                d = 0;
            } else if (p1.penup || p2.penup) {
                d = penupPenalty;
            } else {
                d = ((locationDistance[i][j] / locationDistanceStd) * kAlpha +
                     (directionDistance[i][j] / directionDistanceStd) * (1.0 - kAlpha));
            }
			dtw[i][j] = d + MIN(dtw[i-1][j], MIN(dtw[i-1][j-1], dtw[i][j-1]));
            if (dtw[i-1][j-1] < dtw[i-1][j] && dtw[i-1][j-1] < dtw[i][j-1]) {
                pathlength[i][j] = pathlength[i-1][j-1] + 1;
            } else if (dtw[i-1][j] < dtw[i-1][j-1] && dtw[i-1][j] < dtw[i][j-1]) {
                pathlength[i][j] = pathlength[i-1][j] + 1;
            } else {
                pathlength[i][j] = pathlength[i][j-1] + 1;
            }
		}
	}
	
	return dtw[n-1][m-1] / pathlength[n-1][m-1];
}

- (void)runBatch {
    InkCharacter *ink = [[InkCharacter alloc] init];
    [ink setPoints:_points];
    NSArray *centeredPoints = [[ink centeredCharacter] points];
    NSMutableDictionary *distDictionary = [[NSMutableDictionary alloc] init];
    for (BFPrototype *prototype in _prototypes) {
        float d = [[self class] computeDtwDistanceFromArray:centeredPoints
                                                    toArray:prototype.points];
        if (distDictionary[prototype.label] == nil) {
            distDictionary[prototype.label] = @(d);
        } else {
            float currDist = [distDictionary[prototype.label] floatValue];
            if (d < currDist) {
                distDictionary[prototype.label] = @(d);
            }
        }
    }
    
    float sum_prob = 0;
    for (id key in [distDictionary allKeys]) {
        float d = expf(-[distDictionary[key] floatValue]*kSmoothingFactor);
        distDictionary[key] = @(d);
        sum_prob += d;
    }
    
    [_posterior removeAllObjects];
    for (id key in distDictionary) {
        _posterior[key] = @([distDictionary[key] floatValue] / sum_prob);
        //DEBUG_PRINT(@"%@ %f",key,[_posterior[key] floatValue]);
    }
}

@end
