//
//  BFPrototype.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/12/13.
//
//

#import "BFPrototype.h"
#import "InkCharacter.h"
#import "InkPoint.h"

#define EPS 1e-6

void normalizePointArray(NSArray *pointArray) {
    float min_y = FLT_MAX;
	float max_y = -FLT_MAX;
	float sum_x = 0;
    int numPoints = 0;
    for (InkPoint *point in pointArray) {
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
        for (InkPoint *point in pointArray) {
            if (!point.penup) {
                point.x = (point.x - centerX) / MAX(charHeight, EPS);
                point.y = (point.y - min_y) / MAX(charHeight, EPS);
            }
        }
    }
}

@implementation BFPrototype

- (id)initWithJSONObject:(id)jsonObj {
    self = [super init];
    if (self) {
        _label = [jsonObj[@"label"] copy];
        _prior = [jsonObj[@"prior"] floatValue];
        NSMutableArray *mPointArray = [[NSMutableArray alloc] init];
        for (NSArray *pointInfo in jsonObj[@"center"]) {
            InkPoint *inkPoint = [[InkPoint alloc] init];
            inkPoint.x = [pointInfo[0] floatValue];
            inkPoint.y = [pointInfo[1] floatValue];
            inkPoint.dx = [pointInfo[2] floatValue];
            inkPoint.dy = [pointInfo[3] floatValue];
            inkPoint.penup = [pointInfo[4] boolValue];
            [mPointArray addObject:inkPoint];
        }
        _pointArray = mPointArray;
        normalizePointArray(_pointArray);
    }
    return self;
}

- (int)length {
    return [self.pointArray count];
}

@end
