//
//  NoticeScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/22/13.
//
//

#import "NoticeScene.h"

@implementation NoticeScene {
    SPTextField *_textBox;
}

- (id)initWithText:(NSString *)text {
    self = [super init];
    if (self) {
        int gameWidth = Sparrow.stage.width;
        int gameHeight = Sparrow.stage.height;
        
        _text = text;
        
        // BG
        SPQuad *bg = [SPQuad quadWithWidth:gameWidth-20 height:gameWidth color:0xffffff];
        bg.x = 10;
        bg.y = (gameHeight - bg.height)/2;
        [self addChild:bg];
        
        // Close button
        SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big.png"];
        SPButton *closeButton = [SPButton buttonWithUpState:buttonTexture text:@"Close"];
        closeButton.x = (gameWidth - closeButton.width)/2;
        closeButton.y = bg.y + bg.height - closeButton.height - 20;
        [self addChild:closeButton];
        [closeButton addEventListener:@selector(close) atObject:self
                              forType:SP_EVENT_TYPE_TRIGGERED];
        
        // Text area
        float border = 20;
        _textBox = [SPTextField
                             textFieldWithWidth:bg.width - 2*border
                             height:bg.height - closeButton.height - 20 - border
                             text:text];
        _textBox.x = bg.x + border;
        _textBox.y = bg.y + border;
        _textBox.hAlign = SPHAlignCenter;
        _textBox.vAlign = SPVAlignCenter;
        _textBox.fontSize = 20;
        _textBox.color = 0x000000;
        //_textBox.border = YES;
        [self addChild:_textBox];
    }
    return self;
}

- (void)setText:(NSString *)text {
    _text = text;
    _textBox.text = text;
}

- (void)close {
    [self removeFromParent];
}



@end
