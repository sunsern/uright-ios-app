//
//  Canvas.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "Canvas.h"
#import "BFClassifier.h"
#import "InkPoint.h"
#import "InkCharacter.h"

#define kBrushSize 12.0f
#define kDefaultColor 0x0000ff
#define kSpecialColor 0xff0000
#define kBaseLineRatio 0.70f
#define kTopLineRatio 0.30f
#define kDrawDelta 3.0f
#define kMaxSteps 20

#define ADJUST_X(x) ((x / self.width) * 3.0 - 1.5)
#define UNADJUST_X(x) (((x + 1.5) / 3.0) * self.width)

#define ADJUST_Y(y) ((y / self.height) * 1.3 - 0.15)
#define UNADJUST_Y(y) (((y + 0.15) / 1.3) * self.height)


@implementation Canvas {
    SPImage *_brush;
    SPImage *_canvas;
    SPImage *_guide;
    SPRenderTexture *_renderTexture;
    CGPoint _lastTouch;
    CGPoint _newTouch;
    InkPoint *_marker;
    BOOL _drawing;
}


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


- (id)initWithWidth:(float)width height:(float)height {
    self = [super init];
    if (self) {
        // Create a brush
        _brush = [[SPImage alloc] initWithTexture:[[self class] circleTexture]];
        _brush.pivotX = _brush.width / 2;
        _brush.pivotY = _brush.height / 2;
        _brush.color = kDefaultColor;
        _brush.blendMode = SP_BLEND_MODE_NORMAL;
        
        // Create ruler
        _guide = [[SPImage alloc] initWithTexture:[[self class]
                                                   guideWithWidth:width
                                                   height:height]];
        [self addChild:_guide];
        
        // Create canvas
        _renderTexture = [[SPRenderTexture alloc]
                          initWithWidth:width height:height];
        _canvas = [[SPImage alloc] initWithTexture:_renderTexture];
        [_canvas addEventListener:@selector(onTouch:)
                         atObject:self
                          forType:SP_EVENT_TYPE_TOUCH];
        [_canvas addEventListener:@selector(updateCanvas:)
                         atObject:self
                          forType:SP_EVENT_TYPE_ENTER_FRAME];
        [self addChild:_canvas];
        
        _marker = nil;
        _drawing = NO;
        _firstTouchTime = 0.0;
        _baseline = height * kBaseLineRatio;
        _topline = height * kTopLineRatio;
        _currentInkCharacter = [[InkCharacter alloc] initWithBaseline:_baseline
                                                              topline:_topline];
    }
    return self;
}


- (void)dealloc {
    [_canvas removeEventListenersAtObject:self
                                  forType:SP_EVENT_TYPE_TOUCH];
    [_canvas removeEventListenersAtObject:self
                                  forType:SP_EVENT_TYPE_ENTER_FRAME];
}


- (void)clear {
    // The reset is synced so it can take a while.
    [_classifier reset];
    [_renderTexture clearWithColor:0x000000 alpha:0.0f];
    _marker = nil;
    _drawing = NO;
    _firstTouchTime = 0.0;
    _currentInkCharacter = [[InkCharacter alloc] initWithBaseline:_baseline
                                                          topline:_topline];
}


// Do the drawing
- (void)updateCanvas:(SPEnterFrameEvent *)event {
    if (_drawing) {
        // group the draw calls together for speed
        [_renderTexture drawBundled:^{
            float dx = _newTouch.x - _lastTouch.x;
            float dy = _newTouch.y - _lastTouch.y;
            int numSteps = MIN(MAX((int)(MAX(fabs(dx),
                                             fabs(dy)) / kDrawDelta), 1),
                               kMaxSteps);
            float incX = dx / numSteps;
            float incY = dy / numSteps;
            _brush.x = _lastTouch.x;
			_brush.y = _lastTouch.y;
            // loop through so that if our touches are
            // far apart we still create a line
            for (int i=0; i<numSteps; i++) {
				[_renderTexture drawObject:_brush];
				_brush.x += incX;
                _brush.y += incY;
            }
		}];
		_lastTouch = CGPointMake(_newTouch.x, _newTouch.y);
        _drawing = NO;
    }
    
    if (_marker) {
        _brush.x = _marker.x;
        _brush.y = _marker.y;
        _brush.color = kSpecialColor;
        _brush.scaleX = 2.0;
        _brush.scaleY = 2.0;
        [_renderTexture drawObject:_brush];
        _marker = nil;
        _brush.color = kDefaultColor;
        _brush.scaleX = 1.0;
        _brush.scaleY = 1.0;
    }
}

- (void)onTouch:(SPTouchEvent*)event{
    SPTouch *touchStart = [[event touchesWithTarget:_canvas
                                           andPhase:SPTouchPhaseBegan]
                           anyObject];
	SPPoint *touchPosition;
    if(touchStart){
        touchPosition = [touchStart locationInSpace:_canvas];
		_lastTouch = CGPointMake(touchPosition.x, touchPosition.y);
		_newTouch = CGPointMake(touchPosition.x, touchPosition.y);
         _drawing = YES;
        
        InkPoint *p = [[InkPoint alloc] initWithX:ADJUST_X(_newTouch.x)
                                                y:ADJUST_Y(_newTouch.y)
                                                t:[NSDate timeIntervalSinceReferenceDate]];
        
        if (_firstTouchTime == 0.0) {
            _firstTouchTime = p.t;
        }
        
        [_currentInkCharacter addPoint:p];
        [_classifier addPoint:p];
    }
	SPTouch *touchMove = [[event touchesWithTarget:_canvas
                                          andPhase:SPTouchPhaseMoved]
                          anyObject];
	if(touchMove){
		touchPosition = [touchMove locationInSpace:_canvas];
		_newTouch = CGPointMake(touchPosition.x, touchPosition.y);
        _drawing = YES;
       
        InkPoint *p = [[InkPoint alloc] initWithX:ADJUST_X(_newTouch.x)
                                                y:ADJUST_Y(_newTouch.y)
                                                t:[NSDate timeIntervalSinceReferenceDate]];
        
        [_currentInkCharacter addPoint:p];
        [_classifier addPoint:p];
    }
    
	SPTouch *touchEnd = [[event touchesWithTarget:_canvas
                                         andPhase:SPTouchPhaseEnded]
                         anyObject];
    if(touchEnd){
		touchPosition = [touchEnd locationInSpace:_canvas];
		_lastTouch = CGPointMake(touchPosition.x, touchPosition.y);
		_newTouch = CGPointMake(touchPosition.x, touchPosition.y);
        _drawing = NO;
        
        _lastTouchTime = [NSDate timeIntervalSinceReferenceDate];
        
        InkPoint *p = [[InkPoint alloc] initWithX:ADJUST_X(_newTouch.x)
                                                y:ADJUST_Y(_newTouch.y)
                                                t:[NSDate timeIntervalSinceReferenceDate]];
        p.penup = YES;
        [_currentInkCharacter addPoint:p];
        [_classifier addPoint:p];
	}
}

- (void)drawMarkerAt:(InkPoint *)point {
    _marker = [[InkPoint alloc] initWithX:UNADJUST_X(point.x)
                                        y:UNADJUST_Y(point.y)];
}


- (void)setGuideVisible:(BOOL)visible {
    _guide.visible = visible;
}


@end
