//
//  InkCharacter.h
//  uRight
//
//  Created by Sunsern Cheamanunkul on 4/2/12.
//

#import <Foundation/Foundation.h>

@class InkPoint;

@interface InkCharacter : NSObject

@property (nonatomic,strong,readonly) NSArray *points;
@property float baseLine;
@property float topLine;

- (id)initWithBaseline:(float)baseline topline:(float)topline;

// Add a point
- (void)addPoint:(InkPoint *)point;

// Return a normalized version of this character.
- (InkCharacter *)normalizedCharacter;

// Only center, dont normalize size
- (InkCharacter *)centeredCharacter;

// This is for drawing purposes.
- (InkCharacter *)alignCharacterWithBaseline:(float)baseline 
                                     topline:(float)topline;

// Serialization
- (id)initWithJSONObject:(NSDictionary *)jsonObj;
- (NSDictionary *)toJSONObject;

// Duration of the current character
- (double)duration;

@end
