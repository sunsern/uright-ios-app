//
//  InkPoint.h
//  uRight
//
//  Created by Sunsern Cheamanunkul on 4/2/12.
//

#import <Foundation/Foundation.h>

@interface InkPoint : NSObject

@property (readwrite) float x;
@property (readwrite) float y;
@property (readwrite) double t;
@property (readwrite) float dx;
@property (readwrite) float dy;
@property (readwrite) int penup;


// Initialize the sample point with given x,y and t.
- (id)initWithX:(float)px y:(float)py t:(double)pt penup:(BOOL)penup;

// Initialize the sample point with given x,y and t.
- (id)initWithX:(float)px y:(float)py t:(double)pt;

// Initialize the sample point with given x,y
- (id)initWithX:(float)px y:(float)py;

// Initialize with another InkPoint
- (id)initWithInkPoint:(InkPoint *)ip;

// factory method for a pen-up point
+ (id)penupPoint;

// Compute squared Euclidean distance between two sample points.
+ (double)locationDistanceFrom:(InkPoint *)p1 to:(InkPoint *)p2;
+ (double)directionDistanceFrom:(InkPoint *)p1 to:(InkPoint *)p2;

@end
