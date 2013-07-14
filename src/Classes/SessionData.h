//
//  SessionData.h
//  uRight
//
//  Created by Sunsern Cheamanunkul on 4/12/12.
//

#import <Foundation/Foundation.h>

@class RoundData;

@interface SessionData : NSObject

@property (nonatomic,strong) NSMutableArray *rounds;
@property float bps;
@property float totalScore;
@property float totalTime;
@property int modeId;
@property int userId;
@property int languageId;
@property int classifierId;

// Serialization
- (id)initWithJSONObject:(id)jsonObj;
- (id)toJSONObject;

- (void)addRound:(RoundData *)round;

@end
