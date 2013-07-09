//
//  SessionData.h
//  Handwriting
//
//  Created by Sunsern Cheamanunkul on 4/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class InkExample;
@class ClassificationResult;

@interface SessionData : NSObject {
    NSMutableArray *_packedExampleArray;
    double _totalPauseTime;
    int _totalMultiStrokes;
}

@property double startTime;
@property double endTime;
@property float bps;
@property int modeId;
@property int userId;
@property int languageId;
@property int classifierId;

- (id)initWithUserId:(int)uid
          languageId:(int)lid
              modeId:(int)mid
        classifierId:(int)cid;

// This must be called at the beginning
- (void)beginSession;

// This must be called at the end
- (void)endSession;

// Add an ink example
- (void)addInkExample:(InkExample *)inkExample 
      classificationResult:(ClassificationResult *)result 
                   attempt:(int)attempt;

// Serialization
- (id)initWithJSONObject:(NSDictionary *)jsonObj;
- (NSDictionary *)toJSONObject;
- (NSData *)examplesJSONData;

// Number of examples added so far
- (int)examplesCount;

// Average pause time between strokes
- (double)averagePauseTime;

@end
