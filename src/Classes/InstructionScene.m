//
//  InstructionScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/29/13.
//
//

#import "InstructionScene.h"

@implementation InstructionScene

- (id)initWithImageName:(NSString *)name {
    self = [super init];
    if (self) {
        int gameWidth = Sparrow.stage.width;
        int gameHeight = Sparrow.stage.height;
        
        // BG
        SPQuad *bg = [SPQuad quadWithWidth:gameWidth height:gameHeight color:0x000000];
        bg.alpha = 0.7;
        [self addChild:bg];
        
        // load instruction
        SPImage *instructionImage = [SPImage imageWithContentsOfFile:name];
        [self addChild:instructionImage];
        
        // Close button
        SPTexture *closeTexture = [SPTexture textureWithContentsOfFile:@"close.png"];
        SPButton *closeButton = [SPButton buttonWithUpState:closeTexture];
        closeButton.x = 0;
        closeButton.y = 0;
        closeButton.scaleX = 1.3;
        closeButton.scaleY = 1.3;
        [self addChild:closeButton];
        [closeButton addEventListener:@selector(closeInstruction) atObject:self
                              forType:SP_EVENT_TYPE_TRIGGERED];
    }
    return self;
}


- (void)closeInstruction {
    [self dispatchEventWithType:SP_EVENT_TYPE_SCENE_CLOSE bubbles:YES];
    [self removeFromParent];
}

@end
