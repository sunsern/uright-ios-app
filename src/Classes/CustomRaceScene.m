//
//  CustomRaceScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/19/13.
//
//

#import "CustomRaceScene.h"
#import "Canvas.h"
#import "Charset.h"

#define CUSTOM_CHARSET_ID 0
#define INIT_CHARSET_ID 1

#define IS_SWIPE_RIGHT(dist, speed, angle) \
(dist > 50 && fabs(angle) < M_PI/4 && speed > 500.0)

#define IS_SWIPE_LEFT(dist, speed, angle) \
(dist > 50 && fabs(angle) > 3*M_PI/4 && speed > 500.0)

@implementation CustomRaceScene {
    Canvas *_leftCanvas;
    Canvas *_rightCanvas;
    SPTextField *_label;
    
    SPPoint *_lastTouch;
    double _lastTouchTime;
    
    UITextField *_newLabel;
    
    Charset  *_charset;
    int _currentIdx;
}

- (id)init {
    self = [super init];
    if (self) {
        GlobalStorage *gs = [GlobalStorage sharedInstance];
        UserData *ud = [gs activeUserData];
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
    SPButton *quitButton = [SPButton buttonWithUpState:buttonTexture text:@"Quit"];
    quitButton.x = 0;
    quitButton.y = 0;
    quitButton.scaleX = 0.75;
    quitButton.scaleY = 0.75;
    quitButton.name = @"quit";
    [self addChild:quitButton];
    [quitButton addEventListener:@selector(quit) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
    
    SPButton *addButton = [SPButton buttonWithUpState:buttonTexture text:@"Add new character"];
    addButton.x = 100;
    addButton.name = @"add";
    addButton.scaleX = 0.75;
    addButton.scaleY = 0.75;
    [self addChild:addButton];
    [addButton addEventListener:@selector(addLabel) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
    
    SPButton *removeButton = [SPButton buttonWithUpState:buttonTexture text:@"Remove character"];
    removeButton.x = 200;
    removeButton.name = @"remove";
    removeButton.scaleX = 0.75;
    removeButton.scaleY = 0.75;
    [self addChild:removeButton];
    [removeButton addEventListener:@selector(removeLabel) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
    
    
    _newLabel = [[UITextField alloc] initWithFrame:CGRectMake(150, 50, 150, 30)];
    _newLabel.backgroundColor = [UIColor whiteColor];
    _newLabel.borderStyle = UITextBorderStyleRoundedRect;
    _newLabel.delegate = self;
    _newLabel.placeholder = @"Type a new symbol or words here";
    [Sparrow.currentController.view addSubview:_newLabel];
    
    _label = [SPTextField textFieldWithWidth:150 height:150 text:@""];
    _label.pivotX = _label.width / 2;
    _label.pivotY = _label.height / 2;
    _label.x = gameWidth / 2;
    _label.y = 250;
    _label.border = YES;
    _label.fontSize = 100;
    [self addChild:_label];
    
    // canvas
    _leftCanvas = [[Canvas alloc] initWithWidth:150 height:(150/1.3)];
    _leftCanvas.x = 10;
    _leftCanvas.y = 350;
    _leftCanvas.touchable = NO;
    [self addChild:_leftCanvas];
    
    _rightCanvas = [[Canvas alloc] initWithWidth:150 height:(150/1.3)];
    _rightCanvas.x = gameWidth/2 + 10;
    _rightCanvas.y = 350;
    _rightCanvas.touchable = NO;
    [self addChild:_rightCanvas];
    
    [self addEventListener:@selector(touched:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
    
    _currentIdx = 0;
    [self loadCharacterAtIndex:_currentIdx];
}

- (void)dealloc {
    [self removeEventListenersAtObject:self forType:SP_EVENT_TYPE_TOUCH];
}


- (void)loadCharacterAtIndex:(int)idx {
    if (idx < [_charset.characters count]) {
        _label.text = _charset.characters[idx];
        
        UserData *ud = [[GlobalStorage sharedInstance] activeUserData];
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
        UserData *ud = [[GlobalStorage sharedInstance] activeUserData];
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
        UserData *ud = [[GlobalStorage sharedInstance] activeUserData];
        [ud setCustomCharset:_charset];
        
        [self loadCharacterAtIndex:_currentIdx];
    }
}



- (void)loadNextCharacter {
    if (_currentIdx < [_charset.characters count] - 1) {
        _currentIdx = _currentIdx + 1;
        [self loadCharacterAtIndex:_currentIdx];

//        int gameWidth = Sparrow.stage.width;
//
//        SPTween *move1 = [SPTween tweenWithTarget:_label time:0.2f];
//        [move1 animateProperty:@"x" targetValue:gameWidth+_label.width];
//        [Sparrow.juggler addObject:move1];
//        
//        [Sparrow.juggler delayInvocationByTime:move1.totalTime block:^{
//            [self loadCharacterAtIndex:_currentIdx];
//            _label.x = -_label.width;
//            SPTween *move2 = [SPTween tweenWithTarget:_label time:0.2f];
//            [move2 animateProperty:@"x" targetValue:gameWidth/2];
//            [Sparrow.juggler addObject:move2];
//        }];
    }
}

- (void)loadPreviousCharacter {
    if (_currentIdx > 0) {
        _currentIdx = _currentIdx - 1;
        [self loadCharacterAtIndex:_currentIdx];
    }
}

- (void)quit {
    [_newLabel removeFromSuperview];
    [Sparrow.juggler removeAllObjects];
    [self removeFromParent];
}

- (void)touched:(SPTouchEvent*)event{
    SPTouch *touchStart = [[event touchesWithTarget:self
                                           andPhase:SPTouchPhaseBegan]
                           anyObject];
	SPPoint *touchPosition;
    if(touchStart){
        _lastTouch = [touchStart locationInSpace:self];
        _lastTouchTime = event.timestamp;
	}
    SPTouch *touchEnd = [[event touchesWithTarget:self
                                         andPhase:SPTouchPhaseEnded]
                         anyObject];
    if(touchEnd){
        touchPosition = [touchEnd locationInSpace:self];
        SPPoint *vec = [touchPosition subtractPoint:_lastTouch];
        if (vec.lengthSquared > 1) {
            float dist = vec.length;
            float angle = vec.angle;
            double speed = dist / (event.timestamp - _lastTouchTime);
            if (IS_SWIPE_RIGHT(dist, speed, angle)) {
                NSLog(@"sWipre right?");
                [self loadNextCharacter];
            } else if (IS_SWIPE_LEFT(dist, speed, angle)) {
                NSLog(@"sWipre left?");
                [self loadPreviousCharacter];
            }
        }
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [_newLabel resignFirstResponder];
    return YES;
}

@end
