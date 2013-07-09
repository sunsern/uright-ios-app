//
//  InkPoint.h
//  Handwriting
//
//  Created by Sunsern Cheamanunkul on 4/2/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InkPoint : NSObject

@property (readwrite) float x;
@property (readwrite) float y;
@property (readwrite) double t;
@property (readwrite) float dx;
@property (readwrite) float dy;

// Initialize the sample point with given x and y.
- (id)initWithX:(float)px y:(float)py;

// Initialize the sample point with given x,y and t.
- (id)initWithX:(float)px y:(float)py t:(double)pt;

- (id)initWithInkPoint:(InkPoint *)ip;

// Compute squared Euclidean distance between two sample points.
+ (double)computeDistanceFrom:(InkPoint *)p1 to:(InkPoint *)p2;
+ (double)computeDirectionDifferenceFrom:(InkPoint *)p1 to:(InkPoint *)p2;

@end
