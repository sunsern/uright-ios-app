//
//  Canvas.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "SPSprite.h"

@class BFClassifier;
@class InkPoint;

@interface Canvas : SPSprite

@property (weak) BFClassifier *dtw;
@property double firstTouchTime;
@property double lastTouchTime;

- (id)initWithWidth:(float)width height:(float)height;
- (void)clear;
- (void)drawAtPoint:(InkPoint *)point;

@end
