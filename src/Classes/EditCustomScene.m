//
//  CustomRaceScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/19/13.
//
//

#import "EditCustomScene.h"

#import "Canvas.h"
#import "Charset.h"
#import "GlobalStorage.h"
#import "UserData.h"

#define CUSTOM_CHARSET_ID 0
#define INIT_CHARSET_ID 1

@implementation EditCustomScene {
    Canvas *_leftCanvas;
    Canvas *_rightCanvas;
    SPTextField *_label;
    
    UITextField *_newLabel;
    
    Charset  *_charset;
    int _currentIdx;
}

- (id)init {
    self = [super init];
    if (self) {
        GlobalStorage *gs = [GlobalStorage sharedInstance];
        Userdata *ud = [gs activeUserdata];
        _charset = [ud customCharset];
        if (_charset.charsetID != CUSTOM_CHARSET_ID) {
            _charset.charsetID = CUSTOM_CHARSET_ID;
            // Populate with English
            //Charset *english = [gs charsetByID:INIT_CHARSET_ID];
            //for (NSString *label in english.characters) {
            //    [_charset.characters addObject:label];
            //}
        }
        [ud setCustomCharset:_charset];
        [self setupScene];
    }
    return self;
}


- (void)setupScene {
    int gameWidth = Sparrow.stage.width;
    int gameHeight = Sparrow.stage.height;
    
    // bg
    SPQuad *background = [SPQuad quadWithWidth:gameWidth height:gameHeight];
    [self addChild:background];

    // buttons
    SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big.png"];
    SPButton *backButton = [SPButton buttonWithUpState:buttonTexture text:@"Back"];
    backButton.x = 0;
    backButton.y = 0;
    backButton.scaleX = 1.0;
    backButton.scaleY = 1.0;
    backButton.name = @"quit";
    [self addChild:backButton];
    [backButton addEventListener:@selector(back) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
 
    SPButton *removeButton = [SPButton buttonWithUpState:buttonTexture text:@"Remove character"];
    removeButton.x = gameWidth - removeButton.width;
    removeButton.y = 0;
    removeButton.name = @"remove";
    removeButton.scaleX = 1.0;
    removeButton.scaleY = 1.0;
    [self addChild:removeButton];
    [removeButton addEventListener:@selector(removeLabel) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
    
    _newLabel = [[UITextField alloc] initWithFrame:CGRectMake(gameWidth/2 - 250/2, 90,
                                                              250, 40)];
    _newLabel.backgroundColor = [UIColor whiteColor];
    _newLabel.borderStyle = UITextBorderStyleRoundedRect;
    _newLabel.delegate = self;
    _newLabel.placeholder = @"Type a new symbol or words here";
    _newLabel.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _newLabel.autocorrectionType = UITextAutocorrectionTypeNo;
    _newLabel.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _newLabel.returnKeyType = UIReturnKeyDone;
    [Sparrow.currentController.view addSubview:_newLabel];
    
    _label = [SPTextField textFieldWithWidth:150 height:150 text:@""];
    _label.pivotX = _label.width / 2;
    _label.pivotY = _label.height / 2;
    _label.x = gameWidth / 2;
    _label.y = 250;
    _label.border = YES;
    _label.fontSize = 100;
    _label.fontName = @"AppleColorEmoji";
    _label.autoScale = YES;
    [self addChild:_label];
    
    SPTextField *instruction = [SPTextField
                                textFieldWithWidth:gameWidth
                                height:40
                                text:@"Swipe left and right to nagivate."];
    instruction.x = 0;
    instruction.y = gameHeight - instruction.height;
    [self addChild:instruction];
    
    // canvases
    _leftCanvas = [[Canvas alloc] initWithWidth:150 height:(150/1.3)];
    _leftCanvas.x = 10;
    _leftCanvas.y = 330;
    _leftCanvas.touchable = NO;
    [self addChild:_leftCanvas];
    
    _rightCanvas = [[Canvas alloc] initWithWidth:150 height:(150/1.3)];
    _rightCanvas.x = gameWidth/2 + 10;
    _rightCanvas.y = 330;
    _rightCanvas.touchable = NO;
    [self addChild:_rightCanvas];
    
    [self addEventListener:@selector(touched:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
    
    [self addEventListener:@selector(loadNextCharacter) atObject:self
                   forType:SP_EVENT_TYPE_SWIPE_LEFT];
    [self addEventListener:@selector(loadPreviousCharacter) atObject:self
                   forType:SP_EVENT_TYPE_SWIPE_RIGHT];
    
    
    _currentIdx = 0;
    [self loadCharacterAtIndex:_currentIdx];
}

- (void)dealloc {
    [self removeEventListenersAtObject:self forType:SP_EVENT_TYPE_TOUCH];
}


- (void)loadCharacterAtIndex:(int)idx {
    if (idx >= 0 && idx < [_charset.characters count] &&
        [_charset.characters count] > 0) {
        _label.text = _charset.characters[idx];
        
        Userdata *ud = [[GlobalStorage sharedInstance] activeUserdata];
        NSArray *prots = [ud prototypesWithLabels:@[_label.text]];
        
        [_leftCanvas clear];
        [_rightCanvas clear];
        
        if ([prots count] > 0 && prots[0]) {
            [_leftCanvas drawPrototype:prots[0]];
        }
        if ([prots count] > 1 && prots[1]){
            [_rightCanvas drawPrototype:prots[1]];
        }
    }
}

- (void)addLabel {
    [_newLabel resignFirstResponder];
    if (_newLabel.text.length > 0) {
        [_charset.characters addObject:_newLabel.text];
        Userdata *ud = [[GlobalStorage sharedInstance] activeUserdata];
        [ud setCustomCharset:_charset];
        
        _currentIdx = [_charset.characters count] - 1;
        [self loadCharacterAtIndex:_currentIdx];
        _newLabel.text = @"";
    }
}

- (void)removeLabel {
    if (_currentIdx < [_charset.characters count]) {
        if (_currentIdx == [_charset.characters count]-1){
            [_charset.characters removeObjectAtIndex:_currentIdx];
            _currentIdx = _currentIdx - 1;
        } else {
            [_charset.characters removeObjectAtIndex:_currentIdx];
        }
        Userdata *ud = [[GlobalStorage sharedInstance] activeUserdata];
        [ud setCustomCharset:_charset];
        
        [self loadCharacterAtIndex:_currentIdx];
    }
    if ([_charset.characters count] == 0) {
        _label.text = @"";
        [_leftCanvas clear];
        [_rightCanvas clear];
    }
}


- (void)loadNextCharacter {
    if (_currentIdx < (int)[_charset.characters count] - 1) {
        SPTween *slide_out = [SPTween tweenWithTarget:_label time:0.1];
        [slide_out animateProperty:@"x" targetValue:-_label.width];
        [Sparrow.juggler addObject:slide_out];
        
        [Sparrow.juggler delayInvocationByTime:slide_out.totalTime block:^{
            _currentIdx = _currentIdx + 1;
            [self loadCharacterAtIndex:_currentIdx];
            
            
            int gameWidth = Sparrow.stage.width;
            _label.x = gameWidth + _label.width;
            SPTween *slide_in = [SPTween tweenWithTarget:_label time:0.1];
            [slide_in animateProperty:@"x" targetValue:gameWidth/2];
            [Sparrow.juggler addObject:slide_in];
        }];
    }
}


- (void)loadPreviousCharacter {
    if (_currentIdx > 0) {
        int gameWidth = Sparrow.stage.width;
        SPTween *slide_out = [SPTween tweenWithTarget:_label time:0.1];
        [slide_out animateProperty:@"x" targetValue:gameWidth + _label.width];
        [Sparrow.juggler addObject:slide_out];
        
        [Sparrow.juggler delayInvocationByTime:slide_out.totalTime block:^{
            _currentIdx = _currentIdx - 1;
            [self loadCharacterAtIndex:_currentIdx];
            
            _label.x = -_label.width;
            SPTween *slide_in = [SPTween tweenWithTarget:_label time:0.1];
            [slide_in animateProperty:@"x" targetValue:gameWidth/2];
            [Sparrow.juggler addObject:slide_in];
        }];        
    }
}

- (void)back {
    [_newLabel removeFromSuperview];
    [Sparrow.juggler removeAllObjects];
    [self removeFromParent];
}

- (void)touched:(SPTouchEvent*)event{
    SPTouch *touchStart = [[event touchesWithTarget:self andPhase:SPTouchPhaseBegan]
                           anyObject];
	if (touchStart) {
        // Remove keyboard
        [_newLabel resignFirstResponder];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self addLabel];
    return YES;
}

@end
