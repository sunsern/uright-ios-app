//
//  SessionData.h
//  uRight
//
//  Created by Sunsern Cheamanunkul on 4/12/12.
//

#import <Foundation/Foundation.h>
#import "URJSONSerializable.h"

@class RoundData;

@interface SessionData : NSObject <URJSONSerializable>

@property int userID;
@property int modeID;
@property float bps;
@property float totalScore;
@property float totalTime;
@property (nonatomic,strong) NSMutableArray *rounds;
@property (nonatomic,strong) NSArray *activeCharacters;
@property (nonatomic,strong) NSArray *activeProtosetIDs;

- (void)addRound:(RoundData *)round;

@end
