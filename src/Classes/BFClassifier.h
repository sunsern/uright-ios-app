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

typedef enum {
    BFClassifierModeBatch = 0,
    BFClassifierModeOnline = 1,
    BFClassifierModeEarlyPenup = 2
} BFClassifierMode;


@protocol BFClassifierDelegate
- (void)thresholdReached:(InkPoint *)point;
- (void)updateScore:(float)targetProbability;
@end

@interface BFClassifier : NSObject

@property (readwrite) int beamCount;
@property (readwrite) float targetThreshold;
@property (nonatomic,strong) NSArray *prototypes;
@property (nonatomic,copy) NSString *targetLabel;
@property (nonatomic,weak) id<BFClassifierDelegate> delegate;

- (id)initWithPrototypes:(NSArray *)prototypes mode:(BFClassifierMode)mode;

- (void)reset;

- (void)addPoint:(InkPoint *)point;

- (NSDictionary *)posterior;

@end
