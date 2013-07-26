//
//  RaceReviewScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/21/13.
//
//

#import "RaceReviewScene.h"

#import "Canvas.h"
#import "ClassificationResult.h"
#import "GlobalStorage.h"
#import "RoundData.h"
#import "SessionData.h"
#import "UserData.h"

@implementation RaceReviewScene {
    Canvas *_inkCanvas;
    Canvas *_truePrototype1;
    Canvas *_truePrototype2;
    Canvas *_closestPrototype1;
    Canvas *_closestPrototype2;
    SPTextField *_trueLabelTextField;
    SPTextField *_closestLabelTextField;
    
    NSMutableArray *_mistakes;
    int _currentIdx;
}

- (id)initWithSessionData:(SessionData *)session {
    self = [super init];
    if (self) {
        
        _mistakes = [[NSMutableArray alloc] init];
        for (RoundData *rd in session.rounds) {
            NSString *trueLabel = rd.label;
            NSString *predicted = [rd.result predictionByRanking:0];
            if (predicted && ![trueLabel isEqualToString:predicted]) {
                [_mistakes addObject:rd];
            }
        }
        
        int gameWidth = Sparrow.stage.width;
        int gameHeight = Sparrow.stage.height;
        
        // BG
        SPQuad *bg = [SPQuad quadWithWidth:gameWidth height:gameHeight color:0x799875];
        [self addChild:bg];
        
        _inkCanvas = [[Canvas alloc] initWithWidth:200 height:(200/1.3)];
        _inkCanvas.pivotX = _inkCanvas.width/2;
        _inkCanvas.pivotY = _inkCanvas.height/2;
        _inkCanvas.x = gameWidth/2;
        _inkCanvas.y = gameHeight/2;
        _inkCanvas.touchable = NO;
        [_inkCanvas setGuideVisible:NO];
        [self addChild:_inkCanvas];
        
        _truePrototype1 = [[Canvas alloc] initWithWidth:150 height:(150/1.3)];
        _truePrototype1.pivotX = _truePrototype1.width/2;
        _truePrototype1.pivotY = _truePrototype1.height/2;
        _truePrototype1.x = gameWidth/4;
        _truePrototype1.y = gameHeight/4;
        _truePrototype1.touchable = NO;
        [_truePrototype1 setGuideVisible:NO];
        [self addChild:_truePrototype1];
        
        _truePrototype2 = [[Canvas alloc] initWithWidth:150 height:(150/1.3)];
        _truePrototype2.pivotX = _truePrototype2.width/2;
        _truePrototype2.pivotY = _truePrototype2.height/2;
        _truePrototype2.x = 3*gameWidth/4;
        _truePrototype2.y = gameHeight/4;
        _truePrototype2.touchable = NO;
        [_truePrototype2 setGuideVisible:NO];
        [self addChild:_truePrototype2];
        
        _trueLabelTextField = [SPTextField textFieldWithWidth:150 height:40 text:@""];
        _trueLabelTextField.pivotX = _trueLabelTextField.width/2;
        _trueLabelTextField.pivotY = _trueLabelTextField.height/2;
        _trueLabelTextField.x = gameWidth / 2;
        _trueLabelTextField.y = _inkCanvas.y - _inkCanvas.height/2;
        [self addChild:_trueLabelTextField];
        
        _closestPrototype1 = [[Canvas alloc] initWithWidth:150 height:(150/1.3)];
        _closestPrototype1.pivotX = _closestPrototype1.width/2;
        _closestPrototype1.pivotY = _closestPrototype1.height/2;
        _closestPrototype1.x = gameWidth/4;
        _closestPrototype1.y = 3*gameHeight/4;
        _closestPrototype1.touchable = NO;
        [_closestPrototype1 setGuideVisible:NO];
        [self addChild:_closestPrototype1];
        
        _closestPrototype2 = [[Canvas alloc] initWithWidth:150 height:(150/1.3)];
        _closestPrototype2.pivotX = _closestPrototype2.width/2;
        _closestPrototype2.pivotY = _closestPrototype2.height/2;
        _closestPrototype2.x = 3*gameWidth/4;
        _closestPrototype2.y = 3*gameHeight/4;
        _closestPrototype2.touchable = NO;
        [_closestPrototype2 setGuideVisible:NO];
        [self addChild:_closestPrototype2];
        
        _closestLabelTextField = [SPTextField textFieldWithWidth:150 height:40 text:@""];
        _closestLabelTextField.pivotX = _closestLabelTextField.width/2;
        _closestLabelTextField.pivotY = _closestLabelTextField.height/2;
        _closestLabelTextField.x = gameWidth / 2;
        _closestLabelTextField.y = _inkCanvas.y + _inkCanvas.height/2;
        [self addChild:_closestLabelTextField];
        
        // Back button
        SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big.png"];
        SPButton *backButton = [SPButton buttonWithUpState:buttonTexture text:@"Back"];
        backButton.x = 0;
        backButton.y = 0;
        [self addChild:backButton];
        [backButton addEventListener:@selector(back)
                               atObject:self
                                forType:SP_EVENT_TYPE_TRIGGERED];
        
        SPTextField *instruction = [SPTextField
                                    textFieldWithWidth:gameWidth
                                    height:40
                                    text:@"Swipe left and right to nagivate."];
        instruction.x = 0;
        instruction.y = gameHeight - instruction.height;
        [self addChild:instruction];
        
        [self addEventListener:@selector(prevInk) atObject:self
                       forType:SP_EVENT_TYPE_SWIPE_RIGHT];
        [self addEventListener:@selector(nextInk) atObject:self
                       forType:SP_EVENT_TYPE_SWIPE_LEFT];
        
        _currentIdx = 0;
        [self loadRoundDataAtIndex:_currentIdx];    
    }
    return self;
}

- (void)back {
    [Sparrow.juggler removeAllObjects];
    [self shootUpAndClose];
}

- (void)loadRoundDataAtIndex:(int)index {
    if (index >= 0 && index < [_mistakes count]) {
        RoundData *rd = _mistakes[index];
        GlobalStorage *gs = [GlobalStorage sharedInstance];
        Userdata *ud = [gs activeUserdata];
        
        [_inkCanvas clear];
        [_inkCanvas drawInkCharacter:rd.ink];
        
        // True label
        [_truePrototype1 clear];
        [_truePrototype2 clear];
        NSString *trueLabel = rd.label;
        NSArray *prots = [ud prototypesWithLabels:@[trueLabel]];
        if ([prots count] > 0 && prots[0]) {
            [_truePrototype1 drawPrototype:prots[0]];
        }
        if ([prots count] > 1 && prots[1]){
            [_truePrototype2 drawPrototype:prots[1]];
        }
        _trueLabelTextField.text = [NSString stringWithFormat:@"True label: %@",trueLabel];
        
        // Predicted
        [_closestPrototype1 clear];
        [_closestPrototype2 clear];
        if ([rd.result.scores count] > 0) {
            NSString *predicted = [rd.result predictionByRanking:0];
            prots = [ud prototypesWithLabels:@[predicted]];
            if ([prots count] > 0 && prots[0]) {
                [_closestPrototype1 drawPrototype:prots[0]];
            }
            if ([prots count] > 1 && prots[1]){
                [_closestPrototype2 drawPrototype:prots[1]];
            }
            _closestLabelTextField.text = [NSString stringWithFormat:@"Predicted: %@",predicted];

        }
    }
}

- (void)nextInk {
    if (_currentIdx < (int)[_mistakes count] - 1) {
        SPTween *slide_out = [SPTween tweenWithTarget:_inkCanvas time:0.1];
        [slide_out animateProperty:@"x" targetValue:-_inkCanvas.width];
        [Sparrow.juggler addObject:slide_out];
        
        [Sparrow.juggler delayInvocationByTime:slide_out.totalTime block:^{
            _currentIdx = _currentIdx + 1;
            [self loadRoundDataAtIndex:_currentIdx];
            int gameWidth = Sparrow.stage.width;
            
            _inkCanvas.x = gameWidth + _inkCanvas.width;
            SPTween *slide_in = [SPTween tweenWithTarget:_inkCanvas time:0.1];
            [slide_in animateProperty:@"x" targetValue:gameWidth/2];
            [Sparrow.juggler addObject:slide_in];
        }];
    }
}

- (void)prevInk {
    if (_currentIdx > 0) {
        int gameWidth = Sparrow.stage.width;
        SPTween *slide_out = [SPTween tweenWithTarget:_inkCanvas time:0.1];
        [slide_out animateProperty:@"x" targetValue:gameWidth + _inkCanvas.width];
        [Sparrow.juggler addObject:slide_out];
        
        [Sparrow.juggler delayInvocationByTime:slide_out.totalTime block:^{
            _currentIdx = _currentIdx - 1;
            [self loadRoundDataAtIndex:_currentIdx];
            
            _inkCanvas.x = -_inkCanvas.width;
            SPTween *slide_in = [SPTween tweenWithTarget:_inkCanvas time:0.1];
            [slide_in animateProperty:@"x" targetValue:gameWidth/2];
            [Sparrow.juggler addObject:slide_in];
        }];
    }
}

@end
