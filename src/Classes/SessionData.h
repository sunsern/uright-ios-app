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

@property (nonatomic,strong) NSMutableArray *rounds;
@property float bps;
@property float totalScore;
@property float totalTime;
@property int modeID;
@property int userID;
@property int languageID;
@property int classifierID;

- (void)addRound:(RoundData *)round;

@end
