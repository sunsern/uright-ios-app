//
//  CollectScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "CollectScene.h"

#import "Canvas.h"
#import "BFClassifier.h"
#import "Media.h"
#import "Game.h"
#import "SessionData.h"
#import "RoundData.h"
#import "ClassificationResult.h"
#import "LanguageData.h"
#import "ServerManager.h"

#define MODE_ID 6
#define GAMEWIDTH (Sparrow.stage.width)
#define GAMEHEIGHT (Sparrow.stage.height)

@implementation CollectScene {
    // UI
    NSArray *_textfields;
    SPTextField *_targetLabel;
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
    
    // Background
    SPImage *background = [SPImage imageWithContentsOfFile:@"background.jpg" ];
    background.blendMode = SP_BLEND_MODE_NONE;
    [self addChild:background];
    
    // Canvas background
    SPQuad *canvasBg = [SPQuad quadWithWidth:300 height:220 color:0x333333];
    canvasBg.x = (GAMEWIDTH - canvasBg.width)/2;
    canvasBg.y = 200;
    [self addChild:canvasBg];
    
    _canvas = [[Canvas alloc] initWithWidth:300 height:220];
    _canvas.x = (GAMEWIDTH - _canvas.width)/2;
    _canvas.y = 200;
    [self addChild:_canvas];
    
    SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big.png"];
    SPButton *resetButton = [SPButton buttonWithUpState:buttonTexture text:@"Reset"];
    resetButton.x = 100;
    resetButton.y = 425;
    [self addChild:resetButton];
    [resetButton addEventListener:@selector(onReset) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
    
    _targetLabel = [[SPTextField alloc] initWithWidth:100 height:100];
    _targetLabel.pivotX = _targetLabel.width / 2;
    _targetLabel.pivotY = _targetLabel.height / 2;
    _targetLabel.x = (GAMEWIDTH/2) / 2 + 20;
    _targetLabel.y = 150;
    _targetLabel.text = @"";
    _targetLabel.fontSize = 50;
    [self addChild:_targetLabel];
    
    NSArray *textfieldNames = @[@"totalScore", @"totalTime", @"bps"];
    NSMutableArray *mTextFields = [[NSMutableArray alloc] init];
    for (int i=0; i < [textfieldNames count]; i++) {
        SPTextField *tf = [[SPTextField alloc] initWithWidth:100 height:20];
        tf.x = 200;
        tf.y = 10 + i*20;
        tf.text = @"0.00";
        tf.name = textfieldNames[i];
        [self addChild:tf];
        [mTextFields addObject:tf];
    }
    _textfields = mTextFields;
    
    NSArray *tfLabels = @[@"Total score: ", @"Total time: ", @"BPS: "];
    for (int i=0; i < [tfLabels count]; i++) {
        SPTextField *temp = [[SPTextField alloc] initWithWidth:100 height:20];
        temp.x = 120;
        temp.y = 10 + i*20;
        temp.text = tfLabels[i];
        [self addChild:temp];
    }
    
    // restart button
    SPButton *restart = [SPButton buttonWithUpState:buttonTexture text:@"Restart"];
    restart.x = 20;
    restart.y = 20;
    restart.scaleX = 0.75;
    restart.scaleY = 0.75;
    [self addChild:restart];
    [restart addEventListener:@selector(restartRace) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
    
    // quit button
    SPButton *quit = [SPButton buttonWithUpState:buttonTexture text:@"Quit"];
    quit.x = 20;
    quit.y = 50;
    quit.scaleX = 0.75;
    quit.scaleY = 0.75;
    [self addChild:quit];
    [quit addEventListener:@selector(quitRace) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
    
    // next button
    SPButton *next = [SPButton buttonWithUpState:buttonTexture text:@"next"];
    next.x = 20;
    next.y = 100;
    [self addChild:next];
    [next addEventListener:@selector(endRound) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
    
    
    // Auto start
    [self addEventListener:@selector(restartRace) atObject:self forType:SP_EVENT_TYPE_ADDED_TO_STAGE];
}

- (id)init {
    self = [super init];
    if (self) {
        [self setupScene];
    }
    return self;
}

- (void)dealloc {
    [self removeEventListenersAtObject:self forType:SP_EVENT_TYPE_ADDED_TO_STAGE];
    [_canvas removeEventListenersAtObject:self forType:SP_EVENT_TYPE_TOUCH];
}

- (void)quitRace {
    [Sparrow.juggler removeAllObjects];
    [(Game *)(Sparrow.root) showMenu];
}

- (void)restartRace {
    // Set up classifier
    GlobalStorage *gs = [GlobalStorage sharedInstance];
    UserData *us = [gs activeUser];
    
    _session = [[SessionData alloc] init];
    _session.userID = us.userID;
    _session.languageID = us.languageID;
    _session.modeID = MODE_ID;
    _session.classifierID = _classifier.classifierID;
    
    _targetLabel.text = @"";
    for (SPTextField *tf in _textfields) {
        tf.text = @"0.00";
    }
    
    //NSArray *labelArray = [[[gs languages] languageWithID:[us languageID]] labels];
    _testString = @"กขคง";
    //_testString = [self shuffleArray:labelArray];
    _currentIdx = 0;
    _score = 0;
    _time = 0;
    
    [_canvas clear];
    _canvas.touchable = NO;
    
    SPTextField *banner = [[SPTextField alloc] initWithWidth:100 height:100];
    banner.hAlign = SPHAlignCenter;
    banner.vAlign = SPVAlignCenter;
    banner.pivotX = banner.width/2;
    banner.pivotY = banner.height/2;
    banner.x = GAMEWIDTH/2;
    banner.y = GAMEHEIGHT/2 + 70;
    banner.color = 0x00ff00;
    banner.fontSize = 100;
    [self addChild:banner];
    
    [[Sparrow juggler] delayInvocationByTime:0.25f block:^{
        banner.text = @"3";
        [Media playSound:@"sound.caf"];
    }];
    
    [[Sparrow juggler] delayInvocationByTime:1.25f block:^{
        banner.text = @"2";
        [Media playSound:@"sound.caf"];
    }];
    
    [[Sparrow juggler] delayInvocationByTime:2.25f block:^{
        banner.text = @"1";
        [Media playSound:@"sound.caf"];
    }];
    
    [[Sparrow juggler] delayInvocationByTime:3.25f block:^{
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
    
    for (SPTextField *tf in _textfields) {
        if ([tf.name isEqualToString:@"totalScore"]) {
            tf.text = [NSString stringWithFormat:@"%0.2f", _score];
        } else if ([tf.name isEqualToString:@"totalTime"]) {
            tf.text = [NSString stringWithFormat:@"%0.2f", _time];
        } else if ([tf.name isEqualToString:@"bps"]) {
            tf.text = [NSString stringWithFormat:@"%0.2f", _score/_time];
        }
    }
    
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
    
    _session.totalScore = _score;
    _session.totalTime = _time;
    _session.bps = _score / _time;
    
    // Proceed to summary scene
    [ServerManager uploadSessionData:_session];
    
}

- (void)onReset {
    [_canvas clear];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
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
