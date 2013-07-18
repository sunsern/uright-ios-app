//
//  RaceScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "RaceScene.h"

#import "Canvas.h"
#import "Media.h"
#import "Game.h"
#import "BFClassifier.h"
#import "SessionData.h"
#import "RoundData.h"
#import "ClassificationResult.h"
#import "ServerManager.h"

#define MODE_ID 3
#define RACE_LENGTH 10

#define GAMEWIDTH (Sparrow.stage.width)
#define GAMEHEIGHT (Sparrow.stage.height)

@implementation RaceScene {
    // UI
    NSArray *_textfields;
    SPTextField *_targetLabel;
    Canvas *_canvas;
    SPQuad *_canvasBg;
    SPQuad *_bar;
    
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
    _canvasBg = [SPQuad quadWithWidth:300 height:220 color:0x333333];
    _canvasBg.x = (GAMEWIDTH - _canvasBg.width)/2;
    _canvasBg.y = 200;
    [self addChild:_canvasBg];
    
    _canvas = [[Canvas alloc] initWithWidth:300 height:220];
    _canvas.x = (GAMEWIDTH - _canvas.width)/2;
    _canvas.y = 200;
    [self addChild:_canvas];
    
    [_canvas addEventListener:@selector(onTouch:)
                     atObject:self
                      forType:SP_EVENT_TYPE_TOUCH];
    
    SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big.png"];
    SPButton *resetButton = [SPButton buttonWithUpState:buttonTexture text:@"Reset"];
    resetButton.x = 100;
    resetButton.y = 430;
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
    
    _bar = [[SPQuad alloc] initWithWidth:GAMEWIDTH - 20 height:10];
    _bar.pivotX = _bar.width / 2;
    _bar.x = GAMEWIDTH / 2;
    _bar.y = 185;
    _bar.color = 0x00ee00;
    _bar.visible = NO;
    [self addChild:_bar];
    
    // Auto start
    [self addEventListener:@selector(restartRace) atObject:self forType:SP_EVENT_TYPE_ADDED_TO_STAGE];
}

- (id)initWithPrototypes:(NSArray *)prototypes {
    self = [super init];
    if (self) {
        [self setupScene];
    
        // Setting up classifier
        _classifier = [[BFClassifier alloc] initWithPrototypes:prototypes];
        [_classifier setDelegate:self];
        [_classifier setBeamCount:800];
        [_canvas setClassifier:_classifier];
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
    UserData *ud = [[GlobalStorage sharedInstance] activeUserData];
    
    // Create a new session
    _session = [[SessionData alloc] init];
    _session.userID = ud.userID;
    _session.modeID = MODE_ID;
    
    // Test string
    NSArray *labelArray = ud.activeCharacters;
    _testString = [self shuffleArray:labelArray maxLength:RACE_LENGTH];
    
    _session.activeCharacters = ud.activeCharacters;
    _session.activeProtosetIDs = [ud protosetIDsWithLabels:labelArray];
    
    // Reset UI
    _currentIdx = 0;
    _score = 0;
    _time = 0;
    
    _targetLabel.text = @"";
    for (SPTextField *tf in _textfields) {
        tf.text = @"0.00";
    }

    [_canvas clear];
    _canvas.touchable = NO;
    _canvasBg.color = 0x777777;
    
    // Start count down
    SPTextField *banner = [[SPTextField alloc] initWithWidth:100 height:100];
    banner.hAlign = SPHAlignCenter;
    banner.vAlign = SPVAlignCenter;
    banner.pivotX = banner.width/2;
    banner.pivotY = banner.height/2;
    banner.x = GAMEWIDTH/2;
    banner.y = GAMEHEIGHT/2 + 50;
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
    // Only start when race scene is visible
    if (self.visible) {
        [_canvas clear];
        _canvas.touchable = YES;
        _canvasBg.color = 0x333333;
        _soundPlayed = NO;
        
        _round = [[RoundData alloc] init];
        _round.startTime = [NSDate timeIntervalSinceReferenceDate];
        
        _targetLabel.text = [_testString substringWithRange:NSMakeRange(_currentIdx,1)];
        [_classifier setTargetLabel:_targetLabel.text];
    }
}

- (void)endRound {
    _canvas.touchable = NO;
    _canvasBg.color = 0x777777;
    
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
    
    SPTextField *current_score = [SPTextField textFieldWithText:[NSString stringWithFormat:@"%+0.2f",_currentScore]];
    current_score.x = 120;
    current_score.y = 100;
    current_score.fontSize = 30;
    current_score.color = 0xff0000;
    current_score.alpha = 1.0;
    [self addChild:current_score];
    SPTween *tween = [SPTween tweenWithTarget:current_score time:1.5f];
    tween.delay = 0.0;
    tween.onComplete = ^{ [self removeChild:current_score]; };
    [tween animateProperty:@"y" targetValue:50];
    [tween animateProperty:@"alpha" targetValue:0.0];
    [[Sparrow juggler] addObject:tween];
    
    SPTextField *current_time = [SPTextField textFieldWithText:[NSString stringWithFormat:@"%+0.2f",delta_time]];
    current_time.x = 200;
    current_time.y = 100;
    current_time.fontSize = 30;
    current_time.color = 0x00ff00;
    current_time.alpha = 1.0;
    [self addChild:current_time];
    tween = [SPTween tweenWithTarget:current_time time:1.5f];
    tween.delay = 0.0;
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
     _canvas.touchable = NO;
    
    [_canvas clear];
    
    _session.totalScore = _score;
    _session.totalTime = _time;
    _session.bps = _score / _time;
    
    UserData *ud = [GlobalStorage sharedInstance];
    [ud addScore:_session.bps];
    
    // Proceed to summary scene
    UIAlertView *uploadAlert = [[UIAlertView alloc] initWithTitle:@"Uploading"
                                                          message:@"Please wait while the data is being uploaded"
                                                         delegate:self
                                                cancelButtonTitle:nil
                                                otherButtonTitles:nil];
    [uploadAlert show];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [ServerManager uploadSessionData:_session];
        dispatch_async(dispatch_get_main_queue(), ^ {
            [uploadAlert dismissWithClickedButtonIndex:0 animated:YES];
        });
    });
    
   
}

- (void)onReset {
    [_canvas clear];
    [Sparrow.juggler removeObjectsWithTarget:_bar];
    _bar.width = GAMEWIDTH - 20;
    _bar.visible = NO;
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
    [Sparrow.juggler removeObjectsWithTarget:_bar];
    _bar.width = GAMEWIDTH - 20;
    _bar.visible = NO;
    SPTouch *touchEnd = [[event touchesWithTarget:self andPhase:SPTouchPhaseEnded] anyObject];
    if(touchEnd){
        _bar.visible = YES;
        SPTween *shinking = [[SPTween alloc] initWithTarget:_bar time:1.5];
        [shinking animateProperty:@"width" targetValue:0];
        shinking.onComplete = ^{ [self endRound]; };
        [Sparrow.juggler addObject:shinking];
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

- (NSString *)shuffleArray:(NSArray *)labels maxLength:(int)length {
    NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:labels];
    for (NSInteger i = [labels count] - 1, j; i >= 0; i--)
    {
        j = arc4random() % (i + 1);
        
        NSString *buffer = temp[i];
        temp[i] = temp[j];
        temp[j] = buffer;
    }
    NSMutableString *outStr = [[NSMutableString alloc] init];
    for (int i = 0; i < MIN([labels count], length); i++) {
        [outStr appendString:temp[i]];
    }
    return outStr;
}

@end
