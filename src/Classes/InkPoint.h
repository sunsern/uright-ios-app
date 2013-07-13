//
//  InkPoint.h
//  uRight
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
@property (readwrite) BOOL penup;

// Initialize the sample point with given x and y.
- (id)initWithX:(float)px y:(float)py;

// Initialize the sample point with given x,y and t.
- (id)initWithX:(float)px y:(float)py t:(double)pt;

// Initialize with another InkPoint
- (id)initWithInkPoint:(InkPoint *)ip;

// factory for pen-up point
+ (id)penupPoint;

// Compute squared Euclidean distance between two sample points.
+ (double)locationDistanceFrom:(InkPoint *)p1 to:(InkPoint *)p2;
+ (double)directionDistanceFrom:(InkPoint *)p1 to:(InkPoint *)p2;

@end
