//
//  InkCharacter.m
//  uRight
//
//  Created by Sunsern Cheamanunkul on 4/2/12.
//

#import <float.h>
#import "InkCharacter.h"
#import "InkPoint.h"

#define EPS 1e-5

@implementation InkCharacter  {
    NSMutableArray *_points;
}

@synthesize points = _points;

- (id)init {
	return [self initWithBaseline:0.0 topline:0.0];
}

- (id)initWithBaseline:(float)baseline topline:(float)topline {
	self = [super init];
	if (self) {
		_points = [[NSMutableArray alloc] init];
        _baseLine = baseline;
        _topLine = topline;
	}
	return self;
}

- (void)addPoint:(InkPoint *)point {
    [_points addObject:point];
}

// Returns a normalized version of this character
//  Center x at center of mass along x, height go from 0 -> 1
- (InkCharacter *)normalizedCharacter {
	InkCharacter *normalized = [[InkCharacter alloc] initWithBaseline:_baseLine
                                                              topline:_topLine];
	float min_y = FLT_MAX;
	float max_y = -FLT_MAX;
	float sum_x = 0;
    int numPoints = 0;
    for (InkPoint *point in _points) {
        if (!point.penup) {
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
        for (InkPoint *point in _points) {
            InkPoint *new_point = [[InkPoint alloc] initWithInkPoint:point];
            if (!new_point.penup) {
                new_point.x = (new_point.x - centerX) / MAX(charHeight, EPS);
                new_point.y = (new_point.y - min_y) / MAX(charHeight, EPS);
            }
            [normalized addPoint:new_point];
        }
    }
	return normalized;
}


// Returns a normalized version of this character
// Center-normalization
- (InkCharacter *)centeredCharacter {
	InkCharacter *centered = [[InkCharacter alloc] initWithBaseline:_baseLine
                                                            topline:_topLine];
	float sum_x = 0;
    float sum_y = 0;
    int numPoints = 0;
    for (InkPoint *point in _points) {
        if (!point.penup) {
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
        for (InkPoint *point in _points) {
            InkPoint *new_point = [[InkPoint alloc] initWithInkPoint:point];
            if (!new_point.penup) {
                new_point.x = new_point.x - centerX;
                new_point.y = new_point.y - centerY;
            }
            [centered addPoint:new_point];
        }
    }
	return centered;
}


- (InkCharacter *)alignCharacterWithBaseline:(float)baseline
                                     topline:(float)topline {
    InkCharacter *aligned = [[InkCharacter alloc] initWithBaseline:baseline
                                                            topline:topline];
    float scaleY = (baseline - topline)/(_baseLine - _topLine);
    float min_y = FLT_MAX;
    float sum_x = 0;
    int numPoints = 0;
    for (InkPoint *point in _points) {
        if (!point.penup) {
			float tx = point.x;
            float ty = point.y;
            if (ty < min_y) min_y = ty;
            sum_x = sum_x + tx;
            numPoints++;
		}
	}
    if (numPoints > 0) {
        float centerX = sum_x / numPoints;
        for (InkPoint *point in _points) {
            InkPoint *new_point = [[InkPoint alloc] initWithInkPoint:point];
            if (!new_point.penup) {
                new_point.x = (new_point.x - centerX) * scaleY;
                new_point.y = (new_point.y - _baseLine) * scaleY + baseline;
            }
            [aligned addPoint:new_point];
        }
    }
    return aligned;
}


- (id)initWithJSONObject:(id)jsonObj {
    self = [super init];
    if (self) {
        _baseLine = [jsonObj[@"baseline"] floatValue];
        _topLine = [jsonObj[@"topline"] floatValue];
        _points = [[NSMutableArray alloc] init];
        for (NSDictionary *point in jsonObj[@"points"]) {
            [self addPoint:[[InkPoint alloc]
                            initWithX:[point[@"x"] floatValue]
                            y:[point[@"y"] floatValue]
                            t:[point[@"t"] doubleValue]
                            penup:[point[@"penup"] boolValue]]];
        }
    }
    return self;
}

- (id)toJSONObject {
    NSMutableDictionary *characterInfo = [[NSMutableDictionary alloc] init];
    characterInfo[@"baseline"] = @(_baseLine);
    characterInfo[@"topline"] = @(_topLine);
    NSMutableArray *pointArray = [[NSMutableArray alloc] init];
    for (InkPoint *point in _points) {
        [pointArray addObject: @{
         @"x" : @(point.x),
         @"y" : @(point.y),
         @"t" : @(point.t),
         @"penup" : @(point.penup)}];
    }
    characterInfo[@"points"] = pointArray;
    return characterInfo;
}

- (double)duration {
    InkPoint *firstPoint = [_points objectAtIndex:0];
    InkPoint *lastPoint = [_points lastObject];
    return lastPoint.t - firstPoint.t;
}

@end
