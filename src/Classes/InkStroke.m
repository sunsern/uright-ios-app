//
//  InkStroke.m
//  Handwriting
//
//  Created by Sunsern Cheamanunkul on 4/2/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "InkStroke.h"
#import "InkPoint.h"

@implementation InkStroke

@synthesize points = _points;

- (id)init {
	self = [super init];
	if (self) {
		_points = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)addPoint:(InkPoint *)p {
    if (p != nil) {
        [_points addObject:p];
    }
}

@end
