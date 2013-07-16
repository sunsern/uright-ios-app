//
//  RoundData.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/13/13.
//
//

#import <Foundation/Foundation.h>
#import "URJSONSerializable.h"

@class InkCharacter;
@class ClassificationResult;

@interface RoundData : NSObject <URJSONSerializable>

@property (nonatomic,copy) NSString *label;
@property (nonatomic,strong) InkCharacter *ink;
@property (nonatomic,strong) ClassificationResult *result;
@property double startTime;
@property double firstPendownTime;
@property double lastPenupTime;
@property float score;

@end
