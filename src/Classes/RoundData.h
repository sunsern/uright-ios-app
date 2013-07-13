//
//  RoundData.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/13/13.
//
//

#import <Foundation/Foundation.h>

@class InkCharacter;
@class ClassificationResult;

@interface RoundData : NSObject

@property (nonatomic,copy) NSString *label;
@property (nonatomic,strong) InkCharacter *ink;
@property (nonatomic,strong) ClassificationResult *result;
@property double startTime;
@property double firstPendownTime;
@property double lastPenupTime;
@property float score;

- (NSDictionary *)toJSONObject;


@end
