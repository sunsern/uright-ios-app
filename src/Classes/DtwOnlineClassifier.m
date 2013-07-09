//
//  DtwOnlineClassifier.m
//  uRight2
//
//  Created by Sunsern Cheamanunkul on 12/8/12.
//
//

#import "DtwOnlineClassifier.h"
#import "ExampleSet.h"
#import "InkExample.h"
#import "InkCharacter.h"
#import "InkStroke.h"
#import "InkPoint.h"

#define kAlpha 0.5
#define kSkip 2

#define HASHKEY(x,y) ([NSNumber numberWithInteger:x*1000 + y])


double logsumexp(double x,double y) {
    double temp;
    temp = MAX(x,y);
    return temp + log(exp(x-temp) + exp(y-temp));
}

@implementation PrototypeData
@end

@implementation StateData
@end

@implementation DtwOnlineClassifier

// Convert ink to pointArray by concatenating points and inserting Null
+ (NSArray *)ink2array:(InkCharacter *)ink {
    NSMutableArray *pointArray = [[NSMutableArray alloc] init];
	for (InkStroke *stroke in [ink strokes]) {
        InkPoint *previousPoint = nil;
		for (InkPoint *point in [(InkStroke *)stroke points]) {
            if (previousPoint != nil) {
                float dx = point.x - previousPoint.x;
                float dy = point.y - previousPoint.y;
                float norm = sqrt(dx*dx+dy*dy);
                [point setDx:dx/MAX(norm,1e-5)];
                [point setDy:dy/MAX(norm,1e-5)];
            }
			[pointArray addObject: point];
            previousPoint = point;
		}
        [pointArray addObject: [NSNull null]];
	}
    return pointArray;
}


+ (void)onlineNormalization:(NSArray *)pointArray {
    double sumX = 0.0;
    double sumY = 0.0;
    double sumSqX = 0.0;
    double sumSqY = 0.0;
    int pointcount = 0;
    for (int i = 0; i < [pointArray count]; i++) {
        NSObject *p = [pointArray objectAtIndex:i];
        if (![p isKindOfClass:[NSNull class]]) {
            InkPoint *ip = (InkPoint *)p;
            double x = ip.x;
            double y = ip.y;
            if (i == 0) {
                [ip setX:0.0];
                [ip setY:0.0];
            } else {
                double mean_x = sumX / pointcount;
                double mean_y = sumY / pointcount;
                double h = sqrt(sumSqY / pointcount - mean_y * mean_y);
                [ip setX:(float)((x - mean_x) / MAX(h, 1.0))];
                [ip setY:(float)((y - mean_y) / MAX(h, 1.0))];
                //NSLog(@"%f %f %f",ip.x,ip.y,h);
            }
            sumX += x;
            sumY += y;
            sumSqX += x*x;
            sumSqY += y*y;
            pointcount++;
        }
    }

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
            for (InkExample *inkEx in examples) {
                // Pre-normalized
                InkCharacter *normalized = [[inkEx inkCharacter] normalizedCharacter];
                NSArray *pointArray = [DtwOnlineClassifier ink2array:normalized];
                
                //NSArray *pointArray = [DtwOnlineClassifier ink2array:[InkEx inkCharacter]];
                // TODO: prenormalize this point array
                //[DtwOnlineClassifier onlineNormalization:pointArray];
                
                PrototypeData *pData = [[PrototypeData alloc] init];
                [pData setLabel:label];
                // TODO: replace this with actual prior
                [pData setPrior:0.0];
                [pData setPointArray:pointArray];
                [prototypes addObject:pData];
            }
        }
        _beamCount = 200;
        _prototypes = prototypes;
        _beamPQ = [[JCSuperPriorityQueue alloc] init];
        _likelihood = [[NSMutableDictionary alloc] init];
        [self resetClassifier];
    }
    return self;
}

// async method
- (void)resetClassifier {
    NSLog(@"Reset classifier");
    dispatch_async(_serialQueue, ^{
        [_beamPQ clear];
        for (int i=0; i<[_prototypes count];i++) {
            StateData *s = [[StateData alloc] init];
            [s setAlpha:0];
            [s setPrototypeIdx:i];
            [s setStateIdx:-1];
            [_beamPQ addObject:s value:[s alpha]];
        }
        _pointCount = 0;
        _sumPoint = [[InkPoint alloc] init];
        _sumSqPoint = [[InkPoint alloc] init];
        _prevPoint = nil;
    });
}


- (double)computeCostInkPoint:(InkPoint *)a
                           to:(InkPoint *)b
                          key:(id <NSCopying>)key
                     costDict:(NSMutableDictionary *)costDict {
    NSNumber *ret = [costDict objectForKey:key];
    if (ret != nil) {
        // NSLog(@"cache hit");
        return [ret doubleValue];
    } else {
        double d_dir = [InkPoint computeDirectionDifferenceFrom:a to:b];
        double d_loc = [InkPoint computeDistanceFrom:a to:b];
        
        double d_dir_final = d_dir;
        double d_loc_final = d_loc;
        
        double d_final = kAlpha*d_loc_final + (1.0 - kAlpha)*d_dir_final;
        
        d_final = -d_final;
        
        [costDict setObject:@(d_final) forKey:key];
 
        //NSLog(@"d_final = %f", d_final);
        
        return d_final;
    }  
}

- (double)setCostForStateIdx:(int)stateIdx
                prototypeIdx:(int)prototypeIdx
                previousCost:(double)previousCost
                  inputPoint:(NSObject *)inputPoint
                       pData:(PrototypeData *)pData
                    costDict:(NSMutableDictionary *)costDict
                   stateDict:(NSMutableDictionary *)stateDict {
    // Extract the point
    NSObject *p = [[pData pointArray] objectAtIndex:stateIdx];
    // hash key
    id <NSCopying> key = HASHKEY(prototypeIdx,stateIdx);
    // Compute pointwise cost
    double d = 0;
    if ([p isKindOfClass:[NSNull class]] && [inputPoint isKindOfClass:[NSNull class]]) {
        d = 0.0;
    } else if ([p isKindOfClass:[NSNull class]] || [inputPoint isKindOfClass:[NSNull class]]) {
        d = -100.0;
    } else {
        d = [self computeCostInkPoint:(InkPoint *)inputPoint
                                   to:(InkPoint *)p
                                  key:key
                             costDict:costDict];
    }
    double cost = previousCost + d;
    
    StateData *existingState = [stateDict objectForKey:key];
    if (existingState == nil) {
        StateData *newState = [[StateData alloc] init];
        [newState setPrototypeIdx:prototypeIdx];
        [newState setStateIdx:stateIdx];
        [newState setAlpha:cost];
        [stateDict setObject:newState forKey:key];
    } else {
        //[existingState setAlpha:logsumexp([existingState alpha], cost)];
        [existingState setAlpha:MAX([existingState alpha], cost)];
    }
    
    return cost;
}


// async method
- (void)addPenUp {
    _last_point_time = [NSDate timeIntervalSinceReferenceDate];
    
    dispatch_async(_serialQueue, ^{
        
        //NSLog(@"Adding a pen-up");
        
        NSObject *inputPoint = [NSNull null];
        
        NSMutableDictionary *costDict = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *stateDict = [[NSMutableDictionary alloc] init];
        
        StateData *state = [_beamPQ pop];
        int c = 0;
        while (state != nil && c < _beamCount) {
            double alpha = [state alpha];
            PrototypeData *pData = [_prototypes objectAtIndex:[state prototypeIdx]];
            // Case 1: stay
            [self setCostForStateIdx:[state stateIdx]
                        prototypeIdx:[state prototypeIdx]
                        previousCost:alpha
                          inputPoint:inputPoint
                               pData:pData
                            costDict:costDict
                           stateDict:stateDict];
            // Case 1: move forward
            for (int k = [state stateIdx]+1;
                 k < MIN([state stateIdx]+kSkip,[[pData pointArray] count]); k++) {
                alpha = [self setCostForStateIdx:k
                                    prototypeIdx:[state prototypeIdx]
                                    previousCost:alpha
                                      inputPoint:inputPoint
                                           pData:pData
                                        costDict:costDict
                                       stateDict:stateDict];
            }
            
            state = [_beamPQ pop];
            c++;
        }
        
        [_beamPQ clear];
        
        // pack the new states to the PQ
        [_likelihood removeAllObjects];
            
        for (NSString *key in [stateDict allKeys]) {
            StateData *s = [stateDict objectForKey:key];
            // insert the state to PQ
            if ([s alpha] > -100) {
                
                [_beamPQ addObject:s value:[s alpha]];
                
                //if ([s stateIdx] == [[[_prototypes objectAtIndex:[s prototypeIdx]] pointArray] count] - 1) {
                    // update likelihood
                    NSString *label = [[_prototypes objectAtIndex:[s prototypeIdx]] label];
                    NSNumber *existing = [_likelihood objectForKey:label];
                    if (existing != nil) {
                        [_likelihood setObject:@(logsumexp([existing doubleValue], [s alpha])) forKey:label];
                    } else {
                        [_likelihood setObject:@([s alpha]) forKey:label];
                    }
                //}
            }
        }
        
        double sum_like = -DBL_MAX;
        for (NSString *label in [_likelihood allKeys]) {
            sum_like = logsumexp(sum_like, [_likelihood[label] doubleValue]);
        }
        //NSLog(@"%f",sum_like);
        for (NSString *label in [_likelihood allKeys]) {
            _likelihood[label] = @(exp([_likelihood[label] doubleValue] - sum_like));
        }

        _prevPoint = nil;
        
        //double factor_time = ([NSDate timeIntervalSinceReferenceDate] - _start_time) / (_last_point_time - _start_time);
        
        //double delay_time = ([NSDate timeIntervalSinceReferenceDate] - _last_point_time);

        // Update the prediction
        //[_delegate updateUI:[NSString stringWithFormat:@"%@: %f\ntime: %f\n",best_key,best,factor_time]];
        //dispatch_async(dispatch_get_main_queue(), ^{
        [_delegate updateUI:[_likelihood[_targetLabel] floatValue]];
        //});
    });
}


// async method
- (void)addPointWithX:(float)x y:(float)y t:(double)t {
    
    dispatch_async(_serialQueue, ^{
        
        //NSLog(@"Adding a point");
        
        /*
        InkPoint *inputPoint;
        if (_pointCount == 0) {
            inputPoint = [[InkPoint alloc] initWithX:0.0 y:0.0];
            _start_time = [NSDate timeIntervalSinceReferenceDate];
        } else {
            // compute mean value
            double mean_x = _sumPoint.x / _pointCount;
            double mean_y = _sumPoint.y / _pointCount;
            double h = sqrt(_sumSqPoint.y / _pointCount - mean_y * mean_y);
            
            inputPoint = [[InkPoint alloc] initWithX: (x - mean_x) / MAX(h, 1.0)
                                                   y: (y - mean_y) / MAX(h, 1.0)
                                                   t:t];
            
            // Compute dx,dy
            if (_prevPoint != nil) {
                double dx = x - _prevPoint.x;
                double dy = y - _prevPoint.y;
                double norm = sqrt(dx*dx+dy*dy);
                [inputPoint setDx:dx/MAX(norm,1e-5)];
                [inputPoint setDy:dy/MAX(norm,1e-5)];
            }
        }
        */
        InkPoint *inputPoint = [[InkPoint alloc] initWithX:x y:y t:t];
        if (_prevPoint != nil) {
            double dx = x - _prevPoint.x;
            double dy = y - _prevPoint.y;
            double norm = sqrt(dx*dx+dy*dy);
            [inputPoint setDx:dx/MAX(norm,1e-5)];
            [inputPoint setDy:dy/MAX(norm,1e-5)];
        }
        
        //NSLog(@"(%f,%f)",inputPoint.x, inputPoint.y);
    
        NSMutableDictionary *costDict = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *stateDict = [[NSMutableDictionary alloc] init];
        
        StateData *state = [_beamPQ pop];
        int c = 0;
        while (state != nil && c < _beamCount) {
            //NSLog(@"working state %d, %d %f",[state prototypeIdx],  [state stateIdx], [state alpha]);
            double alpha = [state alpha];
            //NSLog(@"%0.3f",alpha);
            PrototypeData *pData = [_prototypes objectAtIndex:[state prototypeIdx]];
            // Case 1: stay
            if ([state stateIdx] >= 0) {
                [self setCostForStateIdx:[state stateIdx]
                            prototypeIdx:[state prototypeIdx]
                            previousCost:alpha
                              inputPoint:inputPoint
                                   pData:pData
                                costDict:costDict
                               stateDict:stateDict];
            }
            // Case 2: move forward
            for (int k = [state stateIdx]+1;
                 k < MIN([state stateIdx]+kSkip,[[pData pointArray] count]); k++) {
                alpha = [self setCostForStateIdx:k
                                    prototypeIdx:[state prototypeIdx]
                                    previousCost:alpha
                                      inputPoint:inputPoint
                                           pData:pData
                                        costDict:costDict
                                       stateDict:stateDict];
            }
            
            state = [_beamPQ pop];
            c++;
        }
        
        
        //NSLog(@"new dictionary done");
        
        [_beamPQ clear];
        
        // pack the new states to the PQ
        [_likelihood removeAllObjects];
        
        for (NSString *key in [stateDict allKeys]) {
            StateData *s = [stateDict objectForKey:key];
            // insert the state to PQ
            if ([s alpha] > -100) {
                [_beamPQ addObject:s value:[s alpha]];
                
                //if ([s stateIdx] == [[[_prototypes objectAtIndex:[s prototypeIdx]] pointArray] count] - 1) {
                    // update likelihood
                    NSString *label = [[_prototypes objectAtIndex:[s prototypeIdx]] label];
                    NSNumber *existing = [_likelihood objectForKey:label];
                    if (existing != nil) {
                        [_likelihood setObject:@(logsumexp([existing doubleValue], [s alpha])) forKey:label];
                    } else {
                        [_likelihood setObject:@([s alpha]) forKey:label];
                    }
                //}
            }
        }
    
        double sum_like = -DBL_MAX;
        for (NSString *label in [_likelihood allKeys]) {
            double x = [_likelihood[label] doubleValue];
            sum_like = logsumexp(sum_like, x); //[_likelihood[label] doubleValue]);
        }
        //NSLog(@"%f",sum_like);
        for (NSString *label in [_likelihood allKeys]) {
            _likelihood[label] = @(exp([_likelihood[label] doubleValue] - sum_like));
        }
        
        
        //NSLog(@"new PQ done");
        
        // update normalizing var
        //[_sumPoint setX:_sumPoint.x + x];
        //[_sumPoint setY:_sumPoint.y + y];
        //[_sumSqPoint setX:_sumSqPoint.x + x*x];
        //[_sumSqPoint setY:_sumSqPoint.y + y*y];
        //_pointCount++;
        
        _prevPoint = [[InkPoint alloc] initWithX:x y:y];
        
        
        // Update the prediction
        //[_delegate updateUI:[self bestPrediction]];
        //dispatch_async(dispatch_get_main_queue(), ^{
        
        [_delegate updateUI:[_likelihood[_targetLabel] floatValue]];
        
        //});
    });
}

- (NSDictionary *)likelihood {
    return _likelihood;
}

- (NSString *)bestPrediction {
    return [NSString stringWithFormat:@"%0.2f,",
            ([NSDate timeIntervalSinceReferenceDate] - _start_time)/_pointCount];
}

- (void)dealloc {
    dispatch_release(_serialQueue);
}

@end
