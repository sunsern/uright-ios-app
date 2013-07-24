//
//  InkPoint.m
//  uRight
//
//  Created by Sunsern Cheamanunkul on 4/2/12.
//

#import "InkPoint.h"

@implementation InkPoint

- (id)initWithX:(float)px y:(float)py t:(double)pt penup:(BOOL)penup {
	self = [super init];
	if (self) {
		_x = px;
		_y = py;
		_t = pt;
        _dx = 0;
        _dy = 0;
        _penup = penup;
	}
	return self;
}

- (id)initWithX:(float)px y:(float)py t:(double)pt {
	return [self initWithX:px y:py t:pt penup:NO];
}

- (id)initWithX:(float)px y:(float)py {
	return [self initWithX:px y:py t:0 penup:NO];
}

- (id)initWithInkPoint:(InkPoint *)ip {
    InkPoint *np = [self init];
    np.x = ip.x;
    np.y = ip.y;
    np.dx = ip.dx;
    np.dy = ip.dy;
    np.t = ip.t;
    np.penup = ip.penup;
    return np;
}

- (id)init {
	return [self initWithX:0 y:0 t:0 penup:NO];
}

+ (double)locationDistanceFrom:(InkPoint *)p1 to:(InkPoint *)p2 {
	return pow(p1.x - p2.x,2) + pow(p1.y - p2.y,2);
}

+ (double)directionDistanceFrom:(InkPoint *)p1 to:(InkPoint *)p2 {
	return pow(p1.dx - p2.dx,2) + pow(p1.dy - p2.dy,2);
}

+ (id)penupPoint {
    return [[self alloc] initWithX:0 y:0 t:0 penup:YES];
}

@end
