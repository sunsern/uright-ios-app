//
//  InkCharacter.m
//  uRight2
//
//  Created by Sunsern Cheamanunkul on 4/2/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <float.h>
#import "InkCharacter.h"
#import "InkStroke.h"
#import "InkPoint.h"

@implementation InkCharacter

@synthesize strokes = _strokes;

- (id)init {
	return [self initWithBaseline:0.0 topline:0.0];
}

- (id)initWithBaseline:(float)baseline topline:(float)topline {
	self = [super init];
	if (self) {
		_strokes = [[NSMutableArray alloc] init];
        _baseLine = baseline;
        _topLine = topline;
	}
	return self;
}

- (void)addStroke:(InkStroke *)stroke {
    if (stroke != nil) {
        [_strokes addObject:stroke];
    }
}


// Returns a normalized version of this character
//  Center x at center of mass along x, height go from 0 -> 1
- (InkCharacter *)normalizedCharacter {
	InkCharacter *normalized = [[InkCharacter alloc] init];
	float min_y = FLT_MAX;
	float max_y = -FLT_MAX;
	float sum_x = 0;
    int numPoints = 0;
	for (InkStroke *stroke in _strokes) {
		for (InkPoint *point in stroke.points) {
			float tx = point.x;
			float ty = point.y;
            if (ty < min_y) min_y = ty;
			if (ty > max_y) max_y = ty;
            sum_x = sum_x + tx;
            numPoints++;
		}
	}
    if (numPoints > 0) {
        float charHeight = max_y - min_y;
        float centerX = sum_x / numPoints;
        for (InkStroke *stroke in _strokes) {
            InkStroke *new_stroke = [[InkStroke alloc] init];
            for (InkPoint *point in [stroke points]) {
                InkPoint *new_point = [[InkPoint alloc] initWithInkPoint:point];
                new_point.x = (new_point.x - centerX) / charHeight;
                new_point.y = (new_point.y - min_y) / charHeight;
                [new_stroke addPoint:new_point];
            }
            [normalized addStroke:new_stroke];
        }
    }
	return normalized;
}


// Returns a normalized version of this character
// Center-normalization
- (InkCharacter *)centeredCharacter {
	InkCharacter *centered = [[InkCharacter alloc] init];
	float sum_x = 0;
    float sum_y = 0;
    int numPoints = 0;
	for (InkStroke *stroke in _strokes) {
		for (InkPoint *point in stroke.points) {
			float tx = point.x;
			float ty = point.y;
            sum_x = sum_x + tx;
            sum_y = sum_y + ty;
            numPoints++;
		}
	}
    if (numPoints > 0) {
        float centerX = sum_x / numPoints;
        float centerY = sum_y / numPoints;
        for (InkStroke *stroke in _strokes) {
            InkStroke *new_stroke = [[InkStroke alloc] init];
            for (InkPoint *point in [stroke points]) {
                InkPoint *new_point = [[InkPoint alloc] initWithInkPoint:point];
                new_point.x = new_point.x - centerX;
                new_point.y = new_point.y - centerY;
                [new_stroke addPoint:new_point];
            }
            [centered addStroke:new_stroke];
        }
    }
	return centered;
}


- (float)maximumX {
	float max_x = -FLT_MAX;
   	for (InkStroke *stroke in _strokes) {
		for (InkPoint *point in stroke.points) {
			float tx = point.x;
            if (tx > max_x) max_x = tx;
		}
	}
    return max_x;
}


- (InkCharacter *)alignCharacterWithBaseline:(float)baseline topline:(float)topline {
    InkCharacter *newChar = [[InkCharacter alloc] initWithBaseline:baseline topline:topline];
    float scaleY = (baseline - topline)/(_baseLine - _topLine);
    float min_y = FLT_MAX;
    float sum_x = 0;
    int numPoints = 0;
	for (InkStroke *stroke in _strokes) {
		for (InkPoint *point in stroke.points) {
			float tx = point.x;
            float ty = point.y;
            if (ty < min_y) min_y = ty;
            sum_x = sum_x + tx;
            numPoints++;
		}
	}
    if (numPoints > 0) {
        float centerX = sum_x / numPoints;
        for (InkStroke *stroke in _strokes) {
            InkStroke *new_stroke = [[InkStroke alloc] init];
            for (InkPoint *point in [stroke points]) {
                InkPoint *new_point = [[InkPoint alloc] initWithInkPoint:point];
                new_point.x = (new_point.x - centerX) * scaleY;
                new_point.y = (new_point.y - _baseLine) * scaleY + baseline;
                [new_stroke addPoint:new_point];
            }
            [newChar addStroke:new_stroke];
        }
    }
    return newChar;
}

- (id)initWithJSONObject:(NSDictionary *)jsonObj {
    self = [super init];
    if (self) {
        _baseLine = [[jsonObj objectForKey:@"baseline"] floatValue];
        _topLine = [[jsonObj objectForKey:@"topline"] floatValue];
        _direction_z = [[jsonObj objectForKey:@"direction_z"] floatValue];
        _location_z = [[jsonObj objectForKey:@"location_z"] floatValue];
        _strokes = [[NSMutableArray alloc] init];
        for (NSArray *stroke in [jsonObj objectForKey:@"strokes"]) {
            InkStroke *newStroke = [[InkStroke alloc] init];
            for (NSDictionary *point in stroke) {
                float x = [[point objectForKey:@"x"] floatValue];
                float y = [[point objectForKey:@"y"] floatValue];
                double t = [[point objectForKey:@"t"] doubleValue];
                [newStroke addPoint:[[InkPoint alloc] initWithX:x y:y t:t]];
            }   
            [self addStroke:newStroke];
        }
    }
    return self;
}

- (NSDictionary *)toJSONObject {
    NSMutableDictionary *character = [[NSMutableDictionary alloc] initWithCapacity:3];
    NSMutableArray *strokeArray = [[NSMutableArray alloc] initWithCapacity:[_strokes count]];
    for (InkStroke *stroke in _strokes) {
        NSMutableArray *pointArray = [[NSMutableArray alloc] 
                                      initWithCapacity:[[stroke points] count]];
        for (InkPoint *point in [stroke points]) {
            NSMutableDictionary *pointData = [[NSMutableDictionary alloc] initWithCapacity:3];
            [pointData setObject:[NSNumber numberWithFloat:point.x] forKey:@"x"];
            [pointData setObject:[NSNumber numberWithFloat:point.y] forKey:@"y"];
            [pointData setObject:[NSNumber numberWithDouble:point.t] forKey:@"t"];
            [pointArray addObject:pointData];
        }
        [strokeArray addObject:pointArray];
    }
    [character setObject:[NSNumber numberWithFloat:_baseLine] forKey:@"baseline"];
    [character setObject:[NSNumber numberWithFloat:_topLine] forKey:@"topline"];
    [character setObject:strokeArray forKey:@"strokes"];
    return character;
}

- (double)averagePauseTime {
    if ([_strokes count] <= 1) {
        return 0;
    } else {
        double last_t = 0;
        double pt = 0;
        for (int i=0; i < [_strokes count]; i++) {
            InkStroke *stroke = [_strokes objectAtIndex:i];
            InkPoint *first = [[stroke points] objectAtIndex:0];
            InkPoint *last = [[stroke points] lastObject];
            if (i > 0) {
                pt += (first.t - last_t);
            }
            last_t = last.t;
        }
        return pt / ([_strokes count] - 1);
    }
}

- (double)inkDuration {
    InkStroke *firstStroke = [_strokes objectAtIndex:0];
    InkPoint *firstPoint = [[firstStroke points] objectAtIndex:0];
    InkStroke *lastStroke = [_strokes lastObject];
    InkPoint *lastPoint = [[lastStroke points] lastObject];
    return lastPoint.t - firstPoint.t;
}

@end
