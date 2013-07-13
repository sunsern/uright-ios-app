//
//  BFPrototype.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/12/13.
//
//

#import "BFPrototype.h"
#import "InkExample.h"
#import "InkCharacter.h"
#import "InkStroke.h"
#import "InkPoint.h"

NSArray* ink2array(InkCharacter *ink) {
    NSMutableArray *pointArray = [[NSMutableArray alloc] init];
	for (InkStroke *stroke in [ink strokes]) {
        InkPoint *previousPoint = nil;
		for (InkPoint *point in [(InkStroke *)stroke points]) {
            if (previousPoint != nil) {
                float dx = point.x - previousPoint.x;
                float dy = point.y - previousPoint.y;
                float norm = sqrt(dx*dx+dy*dy);
                [point setDx:dx/MAX(norm,1e-5)];
                [point setDy:dy/MAX(norm,1e-5)];
            }
			[pointArray addObject: point];
            previousPoint = point;
		}
        [pointArray addObject:[InkPoint penupPoint]];
	}
    return pointArray;
}

@implementation BFPrototype

- (id)initWithInkExample:(InkExample *)ink prior:(float)prior {
    self = [super init];
    if (self) {
        self.label = ink.label;
        self.prior = prior;
        self.pointArray = ink2array([ink.inkCharacter normalizedCharacter]);
    }
    return self;
}

@end
