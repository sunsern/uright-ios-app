//
//  InkStroke.h
//  Handwriting
//
//  Created by Sunsern Cheamanunkul on 4/2/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class InkPoint;

@interface InkStroke : NSObject {
    NSMutableArray *_points;
}

@property (nonatomic,strong,readonly) NSArray *points;

// Add a new point to the array 
- (void)addPoint:(InkPoint *)p;

@end
