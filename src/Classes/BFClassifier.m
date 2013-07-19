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
#import "JCSuperPriorityQueue.h"

#define kAlpha 0.5
#define kSkip 3
#define kQueueThreshold -10.0
#define kBeamWidth 500
#define kLikelihoodThreshold 1.0
#define kIgnoreAddpoint 0.0002

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
@property (nonatomic, strong) StateData *state;
@end

@implementation CacheData
@end

/////////////////////

static dispatch_queue_t __serialQueue = NULL;

@implementation BFClassifier  {
    JCSuperPriorityQueue *_beamPQ;
    InkPoint *_prevPoint;
    NSMutableDictionary *_likelihood;
    NSMutableDictionary *_finalLikelihood;
    NSMutableDictionary *_cacheDict;
    // Save this for serialization
    NSDictionary *_jsonObj;
}

+ (dispatch_queue_t)serialQueue {
    if (__serialQueue != NULL) {
        return __serialQueue;
    }
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        __serialQueue = dispatch_queue_create("uRight3.BFClassifier", NULL);
    });
    return __serialQueue;
}

- (id)init {
    self = [super init];
    if (self) {
        // create a queue if not yet
        [[self class] serialQueue];
        _beamCount = kBeamWidth;
        _targetThreshold = kLikelihoodThreshold;
        _beamPQ = [[JCSuperPriorityQueue alloc] init];
        _likelihood = [[NSMutableDictionary alloc] init];
        _finalLikelihood = [[NSMutableDictionary alloc] init];
        _cacheDict = [[NSMutableDictionary alloc] init];
        _jsonObj = nil;
    }
    return self;
}

- (id)initWithPrototypes:(NSArray *)prototypes {
    self = [self init];
    _prototypes = [[NSArray alloc] initWithArray:prototypes];
    return self;
}

- (id)initWithJSONObject:(id)jsonObj {
    self = [self init];
    NSMutableArray *prototypes = [[NSMutableArray alloc] init];
    for (id protoJSON in jsonObj[@"prototypes"]) {
        BFPrototype *p = [[BFPrototype alloc] initWithJSONObject:protoJSON];
        [prototypes addObject:p];
    }
    _prototypes = (NSArray *)prototypes;
    _jsonObj = [jsonObj copy];
    return self;
}

- (id)toJSONObject {
    return _jsonObj;
}


// sync method
- (void)reset {
    dispatch_sync([[self class] serialQueue], ^{
        //NSLog(@"Reset classifier");
        [_beamPQ clear];
        for (int i=0; i<[_prototypes count];i++) {
            StateData *state = [[StateData alloc] init];
            state.alpha = log(((BFPrototype *)_prototypes[i]).prior);
            state.prototypeIdx = i;
            state.stateIdx = -1;
            [_beamPQ addObject:state value:state.alpha];
        }
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
        cost = [[self class] computeCostInkPoint:(pData.points)[stateIdx]
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
        [InkPoint locationDistanceFrom:point to:_prevPoint] < kIgnoreAddpoint) {
        //NSLog(@"Point too close to the previous point, ignoring");
        return;
    }
    
    dispatch_async([[self class] serialQueue], ^{
        
        // Compute dx, dy
        if (!point.penup && _prevPoint) {
            float dx = point.x - _prevPoint.x;
            float dy = point.y - _prevPoint.y;
            float norm = sqrt(dx*dx+dy*dy);
            point.dx = dx / MAX(norm,1e-6);
            point.dy = dy / MAX(norm,1e-6);
        }
        
        //[_cacheDict removeAllObjects];
        _cacheDict = [[NSMutableDictionary alloc] init];
        
        StateData *state = [_beamPQ pop];
        
        int c = 0;
        while (state != nil && c < _beamCount) {
            float alpha = [state alpha];
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
        
        [_likelihood removeAllObjects];
        [_finalLikelihood removeAllObjects];
        
        // Normalize live states
        float sum_like = -FLT_MAX;
        for (id key in _cacheDict) {
            CacheData *cache = _cacheDict[key];
            StateData *state = cache.state;
            sum_like = logsumexp(sum_like, state.alpha);
        }
        for (id key in _cacheDict) {
            CacheData *cache = _cacheDict[key];
            StateData *state = cache.state;
            
            // perform normalization
            state.alpha = state.alpha - sum_like;
            // insert the state to PQ
            if (state.alpha > kQueueThreshold) {
                [_beamPQ addObject:state value:state.alpha];
            }
            
            // update likelihood
            NSString *label = [_prototypes[state.prototypeIdx] label];
            NSNumber *existing = _likelihood[label];
            if (existing != nil) {
                _likelihood[label] = @(logsumexp([existing floatValue], state.alpha));
            } else {
                _likelihood[label] = @(state.alpha);
            }
            
            // update final likelihood
            if (state.stateIdx == [_prototypes[state.prototypeIdx] length] - 1) {
                _finalLikelihood[label] = @(state.alpha);
            }
        }
        
        // Likelihood normalization
        sum_like = -FLT_MAX;
        for (id key in _likelihood) {
            float x = [_likelihood[key] floatValue];
            sum_like = logsumexp(sum_like, x);
        }
        for (id key in [_likelihood allKeys]) {
            _likelihood[key] = @(exp([_likelihood[key]
                                      floatValue] - sum_like));
        }
        
        sum_like = -FLT_MAX;
        for (id key in _finalLikelihood) {
            float x = [_finalLikelihood[key] floatValue];
            sum_like = logsumexp(sum_like, x);
        }
        for (id key in [_finalLikelihood allKeys]) {
            _finalLikelihood[key] = @(exp([_finalLikelihood[key]
                                           floatValue] - sum_like));
        }
        
        float p = 1.0 / [_likelihood[_targetLabel] floatValue];
        if (log2(p) < _targetThreshold) {
            [_delegate thresholdReached:point];
        }
        
        if (point.penup) {
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
