//
//  SwipeScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/19/13.
//
//

#import "SwipeScene.h"

#define IS_SWIPE_RIGHT(dist, speed, angle) \
(dist > 50 && fabs(angle) < M_PI/4 && speed > 100.0)

#define IS_SWIPE_LEFT(dist, speed, angle) \
(dist > 50 && fabs(angle) > 3*M_PI/4 && speed > 100.0)

@implementation SwipeScene {
    SPPoint *_lastTouch;
    double _lastTouchTime;
}

- (id)init {
    self = [super init];
    if (self) {
        [self addEventListener:@selector(onTouched:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
    }
    return self;
}


- (void)dealloc {
    [self removeEventListenersAtObject:self forType:SP_EVENT_TYPE_TOUCH];
}


- (void)onTouched:(SPTouchEvent*)event {
    SPTouch *touchStart = [[event touchesWithTarget:self andPhase:SPTouchPhaseBegan]
                           anyObject];
	SPPoint *touchPosition;
    if (touchStart) {
        _lastTouch = [touchStart locationInSpace:self];
        
        _lastTouchTime = event.timestamp;
	}
    SPTouch *touchEnd = [[event touchesWithTarget:self andPhase:SPTouchPhaseEnded]
                         anyObject];
    if (touchEnd) {
        touchPosition = [touchEnd locationInSpace:self];
        SPPoint *vec = [touchPosition subtractPoint:_lastTouch];
        if (vec.lengthSquared > 1) {
            float dist = vec.length;
            float angle = vec.angle;
            double speed = dist / (event.timestamp - _lastTouchTime);
            
            if (IS_SWIPE_RIGHT(dist, speed, angle)) {
                [self dispatchEventWithType:SP_EVENT_TYPE_SWIPE_RIGHT];
            } else if (IS_SWIPE_LEFT(dist, speed, angle)) {
                [self dispatchEventWithType:SP_EVENT_TYPE_SWIPE_LEFT];
            }
        }
    }
}


@end
