//
//  InkPoint.m
//  Handwriting
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

+ (double)computeDistanceFrom:(InkPoint *)p1 to:(InkPoint *)p2 {
	return (p1.x - p2.x) * (p1.x - p2.x) + 
	(p1.y - p2.y) * (p1.y - p2.y);
}

+ (double)computeDirectionDifferenceFrom:(InkPoint *)p1 to:(InkPoint *)p2 {
	return (p1.dx - p2.dx) * (p1.dx - p2.dx) + 
	(p1.dy - p2.dy) * (p1.dy - p2.dy);
}

@end
