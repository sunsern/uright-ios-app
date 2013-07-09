//
//  Canvas.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "Canvas.h"
#import "DtwOnlineClassifier.h"
#import "InkPoint.h"

#define kBrushSize 10
#define kBrushColor [UIColor blueColor]

@implementation Canvas {
    SPImage *_brush;
    SPImage *_canvas;
    SPTexture *_circle;
    SPRenderTexture *_renderTexture;
    CGPoint _lastTouch;
    CGPoint _newTouch;
    BOOL _drawing;
}

- (id)initWithWidth:(float)width height:(float)height {
    self = [super init];
    if (self) {
        
        _circle = [[SPTexture alloc]
                   initWithWidth:kBrushSize
                   height:kBrushSize
                   draw:^(CGContextRef context) {
                       CGRect circle = CGRectMake(0, 0, kBrushSize, kBrushSize);
                       CGContextSetFillColorWithColor(context, kBrushColor.CGColor);
                       CGContextFillEllipseInRect(context, circle);
                   }];
        
        _brush = [[SPImage alloc] initWithTexture:_circle];
        _brush.pivotX = (int)(_brush.width / 2);
        _brush.pivotY = (int)(_brush.height / 2);
        _brush.blendMode = SP_BLEND_MODE_NORMAL;
        
        _renderTexture = [[SPRenderTexture alloc]
                          initWithWidth:width height:height];
        
        _canvas = [[SPImage alloc] initWithTexture:_renderTexture];
        _drawing = NO;
        
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
    [_dtw resetClassifier];
}

- (void)updateCanvas:(SPEnterFrameEvent *)event {
    if (_drawing) {
        // group the draw calls together for speed
		[_renderTexture drawBundled:^{
            int numSteps = 10;
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
		}];
		_lastTouch = CGPointMake(_newTouch.x, _newTouch.y);
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
        
        InkPoint *p = [[InkPoint alloc] initWithX:(_lastTouch.x / self.width)*4.0 - 2.0
                                                y:(_lastTouch.y / self.height)*1.4 - 0.2
                                                t:[NSDate timeIntervalSinceReferenceDate]];
        
        if (_firstTouchTime == 0.0) {
            _firstTouchTime = p.t;
        }
        
        [_dtw addPointWithX:p.x y:p.y t:p.t];
       
    }
	SPTouch *touchMove = [[event touchesWithTarget:self andPhase:SPTouchPhaseMoved] anyObject];
	if(touchMove){
		touchPosition = [touchMove locationInSpace:_canvas];
		_newTouch = CGPointMake(touchPosition.x, touchPosition.y);
        _drawing = YES;
       
        InkPoint *p = [[InkPoint alloc] initWithX:(_lastTouch.x / self.width)*4.0 - 2.0
                                                y:(_lastTouch.y / self.height)*1.4 - 0.2
                                                t:[NSDate timeIntervalSinceReferenceDate]];
     
        
        [_dtw addPointWithX:p.x y:p.y t:p.t];

    }
    
	SPTouch *touchEnd = [[event touchesWithTarget:self andPhase:SPTouchPhaseEnded] anyObject];
    if(touchEnd){
		touchPosition = [touchEnd locationInSpace:_canvas];
		_lastTouch = CGPointMake(touchPosition.x, touchPosition.y);
		_newTouch = CGPointMake(touchPosition.x, touchPosition.y);
        _drawing = NO;
        
        _lastTouchTime = [NSDate timeIntervalSinceReferenceDate];
        
        [_dtw addPenUp];
	}
}


@end
