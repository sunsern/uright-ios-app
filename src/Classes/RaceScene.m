//
//  RaceScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "RaceScene.h"
#import "Canvas.h"
#import "BFClassifier.h"
#import "Media.h"
#import "SessionData.h"
#import "RoundData.h"
#import "ClassificationResult.h"
#import "LanguageData.h"

#define GAMEWIDTH (Sparrow.stage.width)
#define GAMEHEIGHT (Sparrow.stage.height)
@implementation RaceScene {
    // UI
    SPTexture *_buttonTexture;
    SPButton *_resetButton;
    SPImage *_background;
    SPTextField *_targetLabel;
    SPTextField *_totalScore;
    SPTextField *_totalTime;
    SPTextField *_bps;
    Canvas *_canvas;
    
    BFClassifier *_classifier;
    NSString *_testString;
    int _currentIdx;
    float _currentScore;
    float _score;
    float _time;
    BOOL _soundPlayed;
    
    SessionData *_session;
    RoundData *_round;
}


- (void)setupScene {
    _background = [SPImage imageWithContentsOfFile:@"background.jpg" ];
    _background.blendMode = SP_BLEND_MODE_NONE;
    [self addChild:_background];
    
    _canvas = [[Canvas alloc] initWithWidth:300 height:220];
    _canvas.x = (GAMEWIDTH - _canvas.width)/2;
    _canvas.y = 200;
    [_canvas clear];
    [self addChild:_canvas];
    [_canvas addEventListener:@selector(onTouch:)
                     atObject:self
                      forType:SP_EVENT_TYPE_TOUCH];
    
    _buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big.png"];
    _resetButton = [SPButton buttonWithUpState:_buttonTexture text:@"Reset"];
    _resetButton.x = 100;
    _resetButton.y = 425;
    [self addChild:_resetButton];
    [_resetButton addEventListener:@selector(onReset:) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
    
    
    _targetLabel = [[SPTextField alloc] initWithWidth:100 height:100];
    _targetLabel.pivotX = _targetLabel.width / 2;
    _targetLabel.pivotY = _targetLabel.height / 2;
    _targetLabel.x = (GAMEWIDTH/2) / 2 + 20;
    _targetLabel.y = 150;
    _targetLabel.text = @"";
    _targetLabel.fontSize = 50;
    [self addChild:_targetLabel];
    
    _totalScore = [[SPTextField alloc] initWithWidth:100 height:20];
    _totalScore.x = 200;
    _totalScore.y = 10;
    _totalScore.text = @"0.00";
    [self addChild:_totalScore];
    
    _totalTime = [[SPTextField alloc] initWithWidth:100 height:20];
    _totalTime.x = 200;
    _totalTime.y = 30;
    _totalTime.text = @"0.00";
    [self addChild:_totalTime];
    
    _bps = [[SPTextField alloc] initWithWidth:100 height:20];
    _bps.x = 200;
    _bps.y = 50;
    _bps.text = @"0.00";
    [self addChild:_bps];
    
    
    SPTextField *temp;
    temp = [[SPTextField alloc] initWithWidth:100 height:20 text:@"Total score: "];
    temp.x = 120;
    temp.y = 10;
    [self addChild:temp];
    temp = [[SPTextField alloc] initWithWidth:100 height:20 text:@"Total time: "];
    temp.x = 120;
    temp.y = 30;
    [self addChild:temp];
    temp = [[SPTextField alloc] initWithWidth:100 height:20 text:@"BPS: "];
    temp.x = 120;
    temp.y = 50;
    [self addChild:temp];
    
    // restart button
    SPButton *restart = [SPButton buttonWithUpState:_buttonTexture text:@"restart"];
    restart.x = 20;
    restart.y = 20;
    restart.scaleX = 0.75;
    restart.scaleY = 0.75;
    [self addChild:restart];
    [restart addEventListener:@selector(restartRace) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
}

- (id)init {
    self = [super init];
    if (self) {
        [self setupScene];
        
        UserData *us = [[GlobalStorage sharedInstance] activeUser];
        _classifier = [us activeClassifier];
        [_classifier setDelegate:self];
        [_classifier setBeamCount:800];
        
        [_canvas setClassifier:_classifier];
        
    }
    return self;
}


- (void)restartRace {
    _session = [[SessionData alloc] init];
    
    _targetLabel.text = @"";
    _totalScore.text = @"0.00";
    _totalTime.text = @"0.00";
    _bps.text = @"0.00";
    
    //_testString = [self shuffleString:@"abcdefghijklmnopqrstuvwxyz"];
    //_testString = [self shuffleString:@"abc"];
    GlobalStorage *gs = [GlobalStorage sharedInstance];
    UserData *us = [gs activeUser];
    NSArray *labelArray = [[[gs languages] languageWithID:[us languageID]] labels];
    _testString = [self shuffleArray:labelArray];
    _currentIdx = 0;
    _score = 0;
    _time = 0;
    
    [_canvas clear];
    _canvas.touchable = NO;
    
    SPTextField *banner = [[SPTextField alloc] initWithWidth:100 height:100 text:@"3"];
    banner.hAlign = SPHAlignCenter;
    banner.vAlign = SPVAlignCenter;
    banner.pivotX = banner.width/2;
    banner.pivotY = banner.height/2;
    banner.x = GAMEWIDTH/2;
    banner.y =  + 70;
    banner.color = 0x00ff00;
    banner.fontSize = 100;
    [self addChild:banner];
    [Media playSound:@"sound.caf"];
    
    [[Sparrow juggler] delayInvocationByTime:1.0f block:^{
        banner.text = @"2";
        [Media playSound:@"sound.caf"];
    }];
    
    [[Sparrow juggler] delayInvocationByTime:2.0f block:^{
        banner.text = @"1";
        [Media playSound:@"sound.caf"];
    }];
    [[Sparrow juggler] delayInvocationByTime:3.0f block:^{
        [self removeChild:banner];
        [self startRound];
    }];
}


- (void)startRound {
    [_canvas clear];
    _canvas.touchable = YES;
    _soundPlayed = NO;
    
    _round = [[RoundData alloc] init];
    _round.startTime = [NSDate timeIntervalSinceReferenceDate];
    
    _targetLabel.text = [_testString substringWithRange:NSMakeRange(_currentIdx,1)];
    [_classifier setTargetLabel:_targetLabel.text];
}

- (void)endRound {
    _canvas.touchable = NO;
    
    _round.firstPendownTime = _canvas.firstTouchTime;
    _round.lastPenupTime = _canvas.lastTouchTime;
    _round.score = _currentScore;
    _round.ink = _canvas.currentInkCharacter;
    _round.label = _targetLabel.text;
    _round.result = [[ClassificationResult alloc]
                     initWithDictionary:[_classifier finalLikelihood]];
    
    [_session addRound:_round];
    
    float delta_time = _round.lastPenupTime - _round.startTime;
    _score += _currentScore;
    _time += delta_time;
    
    _totalScore.text = [NSString stringWithFormat:@"%0.2f", _score];
    _totalTime.text = [NSString stringWithFormat:@"%0.2f", _time];
    _bps.text = [NSString stringWithFormat:@"%0.2f", _score/_time];
    
    SPTextField *current_score = [SPTextField textFieldWithText:[NSString stringWithFormat:@"%0.2f",_currentScore]];
    current_score.x = 140;
    current_score.y = 100;
    current_score.fontSize = 30;
    current_score.color = 0xff0000;
    current_score.alpha = 1.0;
    [self addChild:current_score];
    SPTween *tween = [SPTween tweenWithTarget:current_score time:1.5f];
    tween.onComplete = ^{ [self removeChild:current_score]; };
    [tween animateProperty:@"y" targetValue:50];
    [tween animateProperty:@"alpha" targetValue:0.0];
    [[Sparrow juggler] addObject:tween];
    
    SPTextField *current_time = [SPTextField textFieldWithText:[NSString stringWithFormat:@"%0.2f",delta_time]];
    current_time.x = 220;
    current_time.y = 100;
    current_time.fontSize = 30;
    current_time.color = 0x00ff00;
    current_time.alpha = 1.0;
    [self addChild:current_time];
    tween = [SPTween tweenWithTarget:current_time time:1.5f];
    tween.onComplete = ^{ [self removeChild:current_time]; };
    [tween animateProperty:@"y" targetValue:50];
    [tween animateProperty:@"alpha" targetValue:0.0];
    [[Sparrow juggler] addObject:tween];
    
    _currentIdx++;
    if (_currentIdx < _testString.length) {
        [self startRound];
    } else {
        [self raceComplete];
    }
}

- (void)raceComplete {
    _targetLabel.text = @"";
    
    [_canvas clear];
}

- (void)onReset:(SPEvent *)event {
    [_canvas clear];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}


- (void)thresholdReached:(InkPoint *)point {
    if (!_soundPlayed) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_canvas drawMarkerAt:point];
            _soundPlayed = YES;
            [Media playSound:@"DING.caf"];
        });
    }
}

- (void)updateScore:(float)targetProb {
    float p = 1.0 / targetProb;
    _currentScore = MAX(log2(26) - log2(p), 0);
}


- (void)onTouch:(SPTouchEvent *)event {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    SPTouch *touchEnd = [[event touchesWithTarget:self andPhase:SPTouchPhaseEnded] anyObject];
    if(touchEnd){
        [self performSelector:@selector(endRound) withObject:nil afterDelay:2.0];
    }
}

- (NSString *)shuffleString:(NSString *)labels {
    NSMutableString *randomizedText = [NSMutableString stringWithString:labels];
    NSString *buffer;
    for (NSInteger i = randomizedText.length - 1, j; i >= 0; i--)
    {
        j = arc4random() % (i + 1);
        
        buffer = [randomizedText substringWithRange:NSMakeRange(i, 1)];
        [randomizedText replaceCharactersInRange:NSMakeRange(i, 1) withString:[randomizedText substringWithRange:NSMakeRange(j, 1)]];
        [randomizedText replaceCharactersInRange:NSMakeRange(j, 1) withString:buffer];
    }
    return randomizedText;
}

- (NSString *)shuffleArray:(NSArray *)labels {
    NSLog(@"%@",labels);
    NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:labels];
    for (NSInteger i = [labels count] - 1, j; i >= 0; i--)
    {
        j = arc4random() % (i + 1);
        
        NSString *buffer = temp[i];
        temp[i] = temp[j];
        temp[j] = buffer;
    }
    NSMutableString *outStr = [[NSMutableString alloc] init];
    for (int i = 0; i < [labels count]; i++) {
        [outStr appendString:temp[i]];
    }
    return outStr;
}

@end
