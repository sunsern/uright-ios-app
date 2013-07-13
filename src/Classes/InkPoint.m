//
//  InkPoint.m
//  uRight
//
//  Created by Sunsern Cheamanunkul on 4/2/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "InkPoint.h"

@implementation InkPoint

- (id)initWithX:(float)px y:(float)py t:(double)pt {
	self = [super init];
	if (self) {
		_x = px;
		_y = py;
		_t = pt;
        _dx = 0;
        _dy = 0;
        _penup = NO;
	}
	return self;
}

- (id)initWithX:(float)px y:(float)py {
	return [self initWithX:px y:py t:0];
}

- (id)initWithInkPoint:(InkPoint *)ip {
    return [self initWithX:ip.x y:ip.y t:ip.t];
}

- (id)init {
	return [self initWithX:0 y:0 t:0];
}

+ (double)locationDistanceFrom:(InkPoint *)p1 to:(InkPoint *)p2 {
	return pow(p1.x - p2.x,2) + pow(p1.y - p2.y,2);
}

+ (double)directionDistanceFrom:(InkPoint *)p1 to:(InkPoint *)p2 {
	return pow(p1.dx - p2.dx,2) + pow(p1.dy - p2.dy,2);
}

- (id)initWithPenUp {
    self = [super init];
	if (self) {
		_x = 0;
		_y = 0;
		_t = 0;
        _dx = 0;
        _dy = 0;
        _penup = YES;
	}
	return self;
}

+ (id)penupPoint {
    return [[self alloc] initWithPenUp];
}

@end
