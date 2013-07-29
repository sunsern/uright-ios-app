//
//  Scene.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "SPSprite.h"

#define SP_EVENT_TYPE_SCENE_CLOSE @"scene_close"

@interface Scene : SPSprite

- (void)dropFromTop;
- (void)dropFromTopNoBounce;
- (void)slideFromRight;
- (void)shootUpAndClose;

@end
