//
//  Scene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "Scene.h"

@implementation Scene


- (void)dropFromTop {
    self.y = -(Sparrow.stage.height);
    SPTween *slidein = [SPTween tweenWithTarget:self time:0.75 transition:SP_TRANSITION_EASE_OUT_BOUNCE];
    slidein.delay = 0.1;
    [slidein animateProperty:@"y" targetValue:0];
    [Sparrow.juggler addObject:slidein];
}

- (void)dropFromTopNoBounce {
    self.y = -(Sparrow.stage.height);
    SPTween *slidein = [SPTween tweenWithTarget:self time:0.40 transition:SP_TRANSITION_LINEAR];
    slidein.delay = 0.1;
    [slidein animateProperty:@"y" targetValue:0];
    [Sparrow.juggler addObject:slidein];
}


- (void)slideFromRight {
    self.x = (Sparrow.stage.width) * 2;
    SPTween *slidein = [SPTween tweenWithTarget:self time:0.35 transition:SP_TRANSITION_LINEAR];
    slidein.delay = 0.1;
    [slidein animateProperty:@"x" targetValue:0];
    [Sparrow.juggler addObject:slidein];
}


- (void)shootUpAndClose {
    SPTween *moveUp = [SPTween tweenWithTarget:self time:0.25];
    [moveUp animateProperty:@"y" targetValue:-(Sparrow.stage.height)];
    moveUp.onComplete = ^{ [self removeFromParent]; };
    [Sparrow.juggler addObject:moveUp];
}

@end
