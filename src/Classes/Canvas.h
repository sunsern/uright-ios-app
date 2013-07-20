//
//  Canvas.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "SPSprite.h"

@class InkPoint;
@class BFClassifier;
@class BFPrototype;
@class InkCharacter;

@interface Canvas : SPSprite

@property float brushSize;
@property (nonatomic,strong) InkCharacter *currentInkCharacter;
@property (nonatomic,weak) BFClassifier *classifier;
@property (readonly) double firstTouchTime;
@property (readonly) double lastTouchTime;
@property (readonly) float baseline;
@property (readonly) float topline;

- (id)initWithWidth:(float)width height:(float)height;
- (void)clear;
- (void)drawMarkerAt:(InkPoint *)point;
- (void)setGuideVisible:(BOOL)visible;
- (void)drawPrototype:(BFPrototype *)prototype;

@end
