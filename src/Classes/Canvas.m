//
//  Canvas.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "Canvas.h"
#import "BFClassifier.h"
#import "BFPrototype.h"
#import "InkPoint.h"
#import "InkCharacter.h"

#define kBrushSize 14.0f
#define kDefaultColor 0x1028da
#define kSpecialColor 0xff0000
#define kPrototypeColor 0x555555
#define kPrototypeScale 0.75
#define kBaseLineRatio 0.75f
#define kTopLineRatio 0.25f
#define kNumSteps 4

#define ADJUST_X(x) (((x - (self.width / 2.0)) / self.height) * 3.00)
#define UNADJUST_X(x) (((x / 3.00) * self.height) + (self.width / 2))

#define ADJUST_Y(y) (((y - (self.height / 2.0)) / self.height) * 3.00)
#define UNADJUST_Y(y) (((y / 3.00) * self.height) + (self.height / 2.0))


@implementation Canvas {
    SPImage *_cleanBrush;
    SPImage *_brush;
    SPImage *_canvas;
    SPImage *_guide;
    SPRenderTexture *_renderTexture;
    CGPoint _lastTouch;
    CGPoint _newTouch;
    BOOL _clearing;
}


- (id)initWithWidth:(float)width height:(float)height {
    self = [super init];
    if (self) {
        // Create brushes
        SPTexture *brushTexture = [SPTexture textureWithContentsOfFile:@"brush.png"];
        _brush = [[SPImage alloc] initWithTexture:brushTexture];
        _brush.pivotX = _brush.width / 2;
        _brush.pivotY = _brush.height / 2;
        _brush.color = kDefaultColor;
        _brush.blendMode = SP_BLEND_MODE_NORMAL;
        
        _cleanBrush = [[SPImage alloc] initWithTexture:[[self class] circleTexture]];
        _cleanBrush.pivotX = _cleanBrush.width / 2;
        _cleanBrush.pivotY = _cleanBrush.height / 2;
        _cleanBrush.color = kDefaultColor;
        _cleanBrush.blendMode = SP_BLEND_MODE_NORMAL;
        
        // Create ruler
        _guide = [[SPImage alloc] initWithTexture:[[self class]
                                                   guideWithWidth:width
                                                   height:height]];
        _guide.touchable = NO;
        [self addChild:_guide];
        
        // Create canvas
        _renderTexture = [[SPRenderTexture alloc]
                          initWithWidth:width height:height];
        _canvas = [[SPImage alloc] initWithTexture:_renderTexture];
        [self addChild:_canvas];
        
        [_canvas addEventListener:@selector(onTouch:) atObject:self
                          forType:SP_EVENT_TYPE_TOUCH];
        
        _clearing = NO;
        _firstTouchTime = 0.0;
        _baseline = ADJUST_Y(height * kBaseLineRatio);
        _topline = ADJUST_Y(height * kTopLineRatio);
        _currentInkCharacter = [[InkCharacter alloc] initWithBaseline:_baseline
                                                              topline:_topline];
                
    }
    return self;
}


- (void)dealloc {
    [_canvas removeEventListenersAtObject:self forType:SP_EVENT_TYPE_TOUCH];
}


- (void)clear {
    if (!_clearing) {
        _clearing = YES;
        // The reset is synced so it can take a while.
        [_classifier reset];
        [_renderTexture clearWithColor:0x000000 alpha:0.0f];
        _firstTouchTime = 0.0;
        _currentInkCharacter = [[InkCharacter alloc] initWithBaseline:_baseline
                                                              topline:_topline];
        _clearing = NO;
    }
}

- (void)drawLine {
    [_renderTexture drawBundled:^{
        float dx = _newTouch.x - _lastTouch.x;
        float dy = _newTouch.y - _lastTouch.y;
        float incX = dx / kNumSteps;
        float incY = dy / kNumSteps;
        _brush.x = _lastTouch.x;
        _brush.y = _lastTouch.y;
        _brush.rotation = [SPUtils randomFloat] * TWO_PI;
        // loop through so that if our touches are
        // far apart we still create a line
        for (int i=0; i<kNumSteps; i++) {
            [_renderTexture drawObject:_brush];
            _brush.x += incX;
            _brush.y += incY;
            _brush.rotation = [SPUtils randomFloat] * TWO_PI;
        }
        _lastTouch = CGPointMake(_brush.x, _brush.y);
    }];
}

- (void)onTouch:(SPTouchEvent*)event {
    SPTouch *touch = [[event touchesWithTarget:_canvas] anyObject];
	SPPoint *touchPosition = [touch locationInSpace:_canvas];
    double touchTime = [NSDate timeIntervalSinceReferenceDate];
    
    if (touch.phase == SPTouchPhaseBegan) {
        _lastTouch = CGPointMake(touchPosition.x, touchPosition.y);
		_newTouch = CGPointMake(touchPosition.x, touchPosition.y);
        
        [self drawLine];
        
        if (_firstTouchTime == 0.0) {
            _firstTouchTime = touchTime;
        }
        
        InkPoint *adj_p = [[InkPoint alloc] initWithX:ADJUST_X(_newTouch.x)
                                                    y:ADJUST_Y(_newTouch.y)
                                                    t:touchTime];
        [_currentInkCharacter addPoint:adj_p];
        [_classifier addPoint:adj_p];
    }
    else if (touch.phase == SPTouchPhaseMoved) {
        _newTouch = CGPointMake(touchPosition.x, touchPosition.y);
        
        [self drawLine];
        
        InkPoint *adj_p = [[InkPoint alloc] initWithX:ADJUST_X(_newTouch.x)
                                                    y:ADJUST_Y(_newTouch.y)
                                                    t:touchTime];
        [_currentInkCharacter addPoint:adj_p];
        [_classifier addPoint:adj_p];
    }
    else if (touch.phase == SPTouchPhaseEnded) {
        _lastTouch = CGPointMake(touchPosition.x, touchPosition.y);
        _newTouch = CGPointMake(touchPosition.x, touchPosition.y);
        
        _lastTouchTime = touchTime;
        
        InkPoint *adj_p = [[InkPoint alloc] initWithX:ADJUST_X(_newTouch.x)
                                                    y:ADJUST_Y(_newTouch.y)
                                                    t:touchTime
                                                penup:YES];
        [_currentInkCharacter addPoint:adj_p];
        [_classifier addPoint:adj_p];
    }
    else {
        DEBUG_PRINT(@"Unhandled touch event!");
    }
}

- (void)drawMarkerAt:(InkPoint *)point {
    InkPoint *marker = [[InkPoint alloc] initWithX:UNADJUST_X(point.x)
                                                y:UNADJUST_Y(point.y)];
    if (marker) {
        _cleanBrush.x = marker.x;
        _cleanBrush.y = marker.y;
        _cleanBrush.color = kSpecialColor;
        _cleanBrush.scaleX = 2.0;
        _cleanBrush.scaleY = 2.0;
        [_renderTexture drawObject:_cleanBrush];
    }
}

- (void)drawPrototype:(BFPrototype *)prototype {
    InkPoint *prev_point = nil;
    for (InkPoint *ip in prototype.points) {
        // convert to screen co-ord
        InkPoint *cur_point = [[InkPoint alloc] initWithInkPoint:ip];
        cur_point.x = UNADJUST_X(cur_point.x);
        cur_point.y = UNADJUST_Y(cur_point.y);
        if (prev_point != nil) {
            float tx = cur_point.x;
            float ty = cur_point.y;
            if (cur_point.penup) {
                tx = prev_point.x;
                ty = prev_point.y;
            }
            float dx = tx - prev_point.x;
            float dy = ty - prev_point.y;
            int numSteps = 20;
            float incX = dx / numSteps;
            float incY = dy / numSteps;
            [_renderTexture drawBundled:^{
                _cleanBrush.x = prev_point.x;
                _cleanBrush.y = prev_point.y;
                _cleanBrush.color = kPrototypeColor;
                _cleanBrush.scaleX = kPrototypeScale;
                _cleanBrush.scaleY = kPrototypeScale;
                // loop through so that if our touches are
                // far apart we still create a line
                for (int i=0; i<numSteps; i++) {
                    [_renderTexture drawObject:_cleanBrush];
                    _cleanBrush.x += incX;
                    _cleanBrush.y += incY;
                }
            }];
        }
        prev_point = cur_point;
        if (prev_point.penup) {
            prev_point = nil;
        }
    }
}

- (void)drawInkCharacter:(InkCharacter *)ink {
    InkPoint *prev_point = nil;
    for (InkPoint *ip in ink.points) {
        // convert to screen co-ord
        InkPoint *cur_point = [[InkPoint alloc] initWithInkPoint:ip];
        cur_point.x = UNADJUST_X(cur_point.x);
        cur_point.y = UNADJUST_Y(cur_point.y);
        if (prev_point != nil) {
            float tx = cur_point.x;
            float ty = cur_point.y;
            if (cur_point.penup) {
                tx = prev_point.x;
                ty = prev_point.y;
            }
            float dx = tx - prev_point.x;
            float dy = ty - prev_point.y;
            int numSteps = 20;
            float incX = dx / numSteps;
            float incY = dy / numSteps;
            [_renderTexture drawBundled:^{
                _cleanBrush.x = prev_point.x;
                _cleanBrush.y = prev_point.y;
                _cleanBrush.color = kDefaultColor;
                _cleanBrush.scaleX = 1.0;
                _cleanBrush.scaleY = 1.0;
                // loop through so that if our touches are
                // far apart we still create a line
                for (int i=0; i<numSteps; i++) {
                    [_renderTexture drawObject:_cleanBrush];
                    _cleanBrush.x += incX;
                    _cleanBrush.y += incY;
                }
            }];
        }
        prev_point = cur_point;
        if (prev_point.penup) {
            prev_point = nil;
        }
    }
}


- (void)setGuideVisible:(BOOL)visible {
    _guide.visible = visible;
}


//////////////// Static textures /////////////////

+ (SPTexture *)circleTexture {
    return [[SPTexture alloc]
            initWithWidth:kBrushSize
            height:kBrushSize
            draw:^(CGContextRef ctx)
            {
                CGRect circle = CGRectMake(0, 0, kBrushSize, kBrushSize);
                CGContextSetFillColorWithColor(ctx,[[UIColor whiteColor]
                                                    CGColor]);
                CGContextFillEllipseInRect(ctx, circle);
            }];
}


+ (SPTexture *)guideWithWidth:(float)width height:(float)height {
    return [[SPTexture alloc]
            initWithWidth:width
            height:height
            draw:^(CGContextRef ctx) {
                CGContextSetLineCap(ctx, kCGLineCapRound);
                CGContextSetLineWidth(ctx, 1.0);
                CGContextSetStrokeColorWithColor(ctx, [[UIColor whiteColor]
                                                       CGColor]);
                // Base line
                CGContextBeginPath(ctx);
                CGContextMoveToPoint(ctx, 0, kBaseLineRatio * height);
                CGContextAddLineToPoint(ctx, width, kBaseLineRatio * height);
                CGContextStrokePath(ctx);
                
                // Top line
                CGContextBeginPath(ctx);
                CGContextMoveToPoint(ctx, 0, kTopLineRatio * height);
                CGContextAddLineToPoint(ctx, width, kTopLineRatio * height);
                CGContextStrokePath(ctx);
                
                // Center line
                CGFloat dash[2] = {6,3};
                CGContextSetLineDash(ctx, 0, dash, 2);
                CGContextBeginPath(ctx);
                CGContextMoveToPoint(ctx, width / 2, 0);
                CGContextAddLineToPoint(ctx, width / 2, height);
                CGContextStrokePath(ctx);
            }];
}

@end
