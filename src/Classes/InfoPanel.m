//
//  InfoPanel.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/27/13.
//
//

#import "InfoPanel.h"
#import "GlobalStorage.h"
#import "Userdata.h"

#define BORDER 8

@implementation InfoPanel {
    SPTextField *_leftTextField;
    SPTextField *_rightTextField;
    SPQuad *_expGained;
    SPQuad *_expNeeded;
    float _expBarWidth;
}

- (id)initWithWidth:(float)width height:(float)height {
    self = [super init];
    if (self) {
        _leftTextField = [SPTextField textFieldWithWidth:(3*width/4-BORDER) height:40 text:@""];
        _leftTextField.x = 4+BORDER;
        _leftTextField.y = 0;
        _leftTextField.hAlign = SPHAlignLeft;
        _leftTextField.color = 0xffffff;
        _leftTextField.fontName = @"Helvetica-Bold";
        _leftTextField.fontSize = 12;
        _leftTextField.autoScale = YES;
        [self addChild:_leftTextField];
        
        _rightTextField = [SPTextField textFieldWithWidth:(width/4-BORDER) height:40 text:@""];
        _rightTextField.x = 3*width/4;
        _rightTextField.y = 0;
        _rightTextField.hAlign = SPHAlignRight;
        _rightTextField.color = 0xffffff;
        _rightTextField.fontName = @"Helvetica-Bold";
        _rightTextField.fontSize = 9;
        _rightTextField.autoScale = YES;
        [self addChild:_rightTextField];
        
        SPTextField *expLabel = [SPTextField textFieldWithWidth:50 height:35 text:@"Exp"];
        expLabel.x = 0;
        expLabel.y = height - expLabel.height;
        expLabel.color = 0xffffff;
        [self addChild:expLabel];
        
        _expBarWidth = width-60;
        _expGained = [SPQuad quadWithWidth:_expBarWidth height:10 color:0x00ff00];
        _expGained.x = 50;
        _expGained.y = height - _expGained.height - 10;
        [self addChild:_expGained];
        
        _expNeeded = [SPQuad quadWithWidth:0 height:10 color:0xffffff];
        _expNeeded.x = _expGained.x + _expGained.width;
        _expNeeded.y = height - _expNeeded.height - 10;
        [self addChild:_expNeeded];
    }
    return self;
}

- (void)updatePanel {
    Userdata *ud = [[GlobalStorage sharedInstance] activeUserdata];
    NSString *normalizedUsername;
    if ([ud.username hasPrefix:@"PF_"]) {
        NSArray *components = [ud.username componentsSeparatedByString:@"_"];
        normalizedUsername = components[1];
    }
    else if ([ud.username hasPrefix:@"FB_"]) {
        NSArray *components = [ud.username componentsSeparatedByString:@"_"];
        normalizedUsername = [NSString stringWithFormat:@"%@ (FB)", components[1]];
    }
    _leftTextField.text = [NSString stringWithFormat:@"Level %d :: %@",
                           ud.level, normalizedUsername];
    _rightTextField.text = [NSString stringWithFormat:@"%d\ncharacters", [ud.protosets count]];
    _expGained.width = _expBarWidth * ud.experience / (ud.experience + ud.nextLevelExp);
    _expNeeded.width = _expBarWidth * ud.nextLevelExp / (ud.experience + ud.nextLevelExp);
    _expNeeded.x = _expGained.x + _expGained.width;
}

@end
