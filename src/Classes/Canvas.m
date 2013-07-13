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

#define kBrushSize 10
#define kDefaultColor 0x0000ff
#define kSpecialColor 0xff0000

@implementation Canvas {
    SPImage *_brush;
    SPImage *_canvas;
    SPTexture *_circle;
    SPRenderTexture *_renderTexture;
    CGPoint _lastTouch;
    CGPoint _newTouch;
    BOOL _drawing;
    InkPoint *_marker;
}

- (id)initWithWidth:(float)width height:(float)height {
    self = [super init];
    if (self) {
        
        _circle = [[SPTexture alloc]
                   initWithWidth:kBrushSize
                   height:kBrushSize
                   draw:^(CGContextRef context) {
                       CGRect circle = CGRectMake(0, 0, kBrushSize, kBrushSize);
                       CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
                       CGContextFillEllipseInRect(context, circle);
                   }];
        
        _brush = [[SPImage alloc] initWithTexture:_circle];
        _brush.pivotX = (int)(_brush.width / 2);
        _brush.pivotY = (int)(_brush.height / 2);
        _brush.color = kDefaultColor;
        _brush.blendMode = SP_BLEND_MODE_NORMAL;
        
        _renderTexture = [[SPRenderTexture alloc]
                          initWithWidth:width height:height];
        
        _canvas = [[SPImage alloc] initWithTexture:_renderTexture];
        _drawing = NO;
        _marker = nil;
        
        [self addChild:_canvas];
        
        [_canvas addEventListener:@selector(onTouch:)
                         atObject:self
                          forType:SP_EVENT_TYPE_TOUCH];
        [_canvas addEventListener:@selector(updateCanvas:)
                         atObject:self
                          forType:SP_EVENT_TYPE_ENTER_FRAME];
        
        _firstTouchTime = 0.0;
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
    [_renderTexture clearWithColor:0x000000 alpha:1.0f];
    [_dtw reset];
    _marker = nil;
}

- (void)updateCanvas:(SPEnterFrameEvent *)event {
    if (_drawing) {
        // group the draw calls together for speed
		[_renderTexture drawBundled:^{
            int numSteps = 8;
            double incX = (_newTouch.x - _lastTouch.x)/numSteps;
			double incY = (_newTouch.y - _lastTouch.y)/numSteps;
			_brush.x = _lastTouch.x;
			_brush.y = _lastTouch.y;
            // loop through so that if our touches are far apart we still create a line
			for (int i=0; i<numSteps; i++){
				[_renderTexture drawObject:_brush];
				_brush.x += incX;
				_brush.y += incY;
            }
            
            if (_marker) {
                _brush.x = _marker.x;
                _brush.y = _marker.y;
                _brush.scaleX = 2.0;
                _brush.scaleY = 2.0;
                _brush.color = kSpecialColor;
                [_renderTexture drawObject:_brush];
                _marker = nil;
                _brush.color = kDefaultColor;
                _brush.scaleX = 1.0;
                _brush.scaleY = 1.0;
            }
            
		}];
		_lastTouch = CGPointMake(_newTouch.x, _newTouch.y);
    }
    
    if (_marker) {
        _brush.x = _marker.x;
        _brush.y = _marker.y;
        _brush.scaleX = 2.0;
        _brush.scaleY = 2.0;
        _brush.color = kSpecialColor;
        [_renderTexture drawObject:_brush];
        _marker = nil;
        _brush.color = kDefaultColor;
        _brush.scaleX = 1.0;
        _brush.scaleY = 1.0;
    }
}

- (void)onTouch:(SPTouchEvent*)event{
    SPTouch *touchStart = [[event touchesWithTarget:self andPhase:SPTouchPhaseBegan] anyObject];
	SPPoint *touchPosition;
    if(touchStart){
        touchPosition = [touchStart locationInSpace:_canvas];
		_lastTouch = CGPointMake(touchPosition.x, touchPosition.y);
		_newTouch = CGPointMake(touchPosition.x, touchPosition.y);
         _drawing = YES;
        
        float w = self.width;
        float h = self.height;
        InkPoint *p = [[InkPoint alloc] initWithX:(_lastTouch.x/w)*3.0 - 1.5
                                                y:(_lastTouch.y/h)*1.3 - 0.15
                                                t:[NSDate timeIntervalSinceReferenceDate]];
        
        if (_firstTouchTime == 0.0) {
            _firstTouchTime = p.t;
        }
        
        [_dtw addPoint:p];
       
    }
	SPTouch *touchMove = [[event touchesWithTarget:self andPhase:SPTouchPhaseMoved] anyObject];
	if(touchMove){
		touchPosition = [touchMove locationInSpace:_canvas];
		_newTouch = CGPointMake(touchPosition.x, touchPosition.y);
        _drawing = YES;
       
        float w = self.width;
        float h = self.height;
        InkPoint *p = [[InkPoint alloc] initWithX:(_lastTouch.x/w)*3.0 - 1.5
                                                y:(_lastTouch.y/h)*1.3 - 0.15
                                                t:[NSDate timeIntervalSinceReferenceDate]];
        [_dtw addPoint:p];

    }
    
	SPTouch *touchEnd = [[event touchesWithTarget:self andPhase:SPTouchPhaseEnded] anyObject];
    if(touchEnd){
		touchPosition = [touchEnd locationInSpace:_canvas];
		_lastTouch = CGPointMake(touchPosition.x, touchPosition.y);
		_newTouch = CGPointMake(touchPosition.x, touchPosition.y);
        _drawing = NO;
        
        _lastTouchTime = [NSDate timeIntervalSinceReferenceDate];
        
        float w = self.width;
        float h = self.height;
        InkPoint *p = [[InkPoint alloc] initWithX:(_lastTouch.x/w)*3.0 - 1.5
                                                y:(_lastTouch.y/h)*1.3 - 0.15
                                                t:[NSDate timeIntervalSinceReferenceDate]];
        p.penup = YES;
        [_dtw addPoint:p];
	}
}

- (void)drawAtPoint:(InkPoint *)point {
    _marker = [[InkPoint alloc] initWithInkPoint:point];
    _marker.x = ((point.x + 1.5) / 3.0) * self.width;
    _marker.y = ((point.y + 0.15) / 1.3) * self.height;
    NSLog(@"%f %f", _marker.x, _marker.y);
}

@end
