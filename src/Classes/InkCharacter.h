//
//  InkCharacter.h
//  uRight2
//
//  Created by Sunsern Cheamanunkul on 4/2/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class InkStroke;

@interface InkCharacter : NSObject {
    NSMutableArray *_strokes;
}

@property (nonatomic,strong,readonly) NSArray *strokes;
@property float baseLine;
@property float topLine;
@property float location_z;
@property float direction_z;

- (id)initWithBaseline:(float)baseline topline:(float)topline;

// Add a stroke
- (void)addStroke:(InkStroke *)stroke;

// Return a normalized version of this character.
- (InkCharacter *)normalizedCharacter;

- (InkCharacter *)centeredCharacter;

// This is for drawing purposes.
- (InkCharacter *)alignCharacterWithBaseline:(float)baseline 
                                     topline:(float)topline;

// Serialization
- (id)initWithJSONObject:(NSDictionary *)jsonObj;
- (NSDictionary *)toJSONObject;

// Average pause time between strokes
- (double)averagePauseTime;

// Duration of the inking
- (double)inkDuration;

// maximum x
- (float)maximumX;

@end
