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
#import "RaceSummaryScene.h"
#import "ServerManager.h"
#import "MBProgressHUD.h"
#import "GlobalStorage.h"
#import "Userdata.h"
#import "InstructionScene.h"

#define RACE_LENGTH 15
#define WAIT_TIME 1.0f

@implementation RaceScene {
    int _modeID;
    
    // UI
    SPTextField *_targetLabel;
    SPTextField *_bpsTextField;
    Canvas *_canvas;
    SPQuad *_bar;
    
    BFClassifier *_classifier;
    BFClassifierMode _classifierMode;
    NSArray *_activeCharacters;
    NSArray *_testArray;
    int _currentIdx;
    float _currentScore;
    float _totalScore;
    float _totalTime;
    double _roundTime;
    BOOL _earlyStopFound;
    CGPoint _targetLabelCenter;
    
    SessionData *_session;
    RoundData *_round;
}


- (id)initWithCharacters:(NSArray *)characters classifierMode:(BFClassifierMode)classifierMode modeID:(int)modeID {
    self = [super init];
    if (self) {
        [self setupScene];
        _activeCharacters = [[NSArray alloc] initWithArray:characters];
        _classifierMode = classifierMode;
        _modeID = modeID;
    }
    return self;
}


- (void)setupScene {
    int gameWidth = Sparrow.stage.width;
    int gameHeight = Sparrow.stage.height;
    int y_offset = 0;
    
    if (gameHeight > 480) {
        y_offset = 40;
    }
    
    // Background
    SPImage *background = [SPImage imageWithContentsOfFile:@"background.jpg" ];
    background.touchable = NO;
    [self addChild:background];
    
    // Canvas background
    SPQuad *canvasBg = [SPQuad quadWithWidth:300 height:220 color:0x555555];
    canvasBg.x = (gameWidth - canvasBg.width)/2;
    canvasBg.y = y_offset + 210;
    canvasBg.alpha = 0.9;
    canvasBg.touchable = NO;
    [self addChild:canvasBg];
    
    // Target character BG
    SPQuad *tcBg = [SPQuad quadWithWidth:100 height:100 color:0x333333];
    tcBg.x = canvasBg.x;
    tcBg.y = canvasBg.y - tcBg.height - 40;
    tcBg.alpha = 0.8;
    _targetLabelCenter = CGPointMake(tcBg.x + tcBg.width/2,
                                     tcBg.y + tcBg.height/2);
    tcBg.touchable = NO;
    [self addChild:tcBg];
    
    // The canvas
    _canvas = [[Canvas alloc] initWithWidth:canvasBg.width height:canvasBg.height];
    _canvas.x = (gameWidth - _canvas.width)/2;
    _canvas.y = canvasBg.y;
    [self addChild:_canvas];
    [_canvas addEventListener:@selector(onTouch:) atObject:self
                      forType:SP_EVENT_TYPE_TOUCH];

    
    // Next character bar
    _bar = [[SPQuad alloc] initWithWidth:_canvas.width height:15];
    _bar.pivotX = _bar.width / 2;
    _bar.x = gameWidth / 2;
    _bar.y = _canvas.y - _bar.height;
    _bar.color = 0x59aa53;
    [self addChild:_bar];
    
    // Target character
    _targetLabel = [SPTextField textFieldWithWidth:100 height:100 text:@""];
    _targetLabel.hAlign = SPHAlignCenter;
    _targetLabel.vAlign = SPVAlignCenter;
    _targetLabel.pivotX = _targetLabel.width / 2;
    _targetLabel.pivotY = _targetLabel.height / 2;
    _targetLabel.fontSize = 72;
    _targetLabel.color = 0xdfd371;
    _targetLabel.fontName = @"AppleColorEmoji";
    //_targetLabel.border = YES;
    _targetLabel.autoScale = YES;
    _targetLabel.touchable = NO;
    [self addChild:_targetLabel];

    // Erase button
    SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"erase-button.png"];
    SPButton *resetButton = [SPButton buttonWithUpState:buttonTexture];
    resetButton.pivotX = resetButton.width / 2;
    resetButton.pivotY = resetButton.height / 2;
    resetButton.x = gameWidth / 2;
    resetButton.y = _canvas.y + _canvas.height + resetButton.height/2;
    resetButton.scaleX = 0.9;
    resetButton.scaleY = 0.9;
    [self addChild:resetButton];
    [resetButton addEventListener:@selector(reset) atObject:self
                          forType:SP_EVENT_TYPE_TRIGGERED];
   
    // BPS meter
    _bpsTextField = [SPTextField textFieldWithWidth:100 height:50 text:@""];
    _bpsTextField.x = gameWidth/2 + 20;
    _bpsTextField.y = y_offset + 5;
    _bpsTextField.fontSize = 40;
    _bpsTextField.fontName = @"ArialRoundedMTBold";
    _bpsTextField.border = YES;
    //_bpsTf.autoScale = YES;
    [self addChild:_bpsTextField];
    
    SPTextField *bpsLabel = [SPTextField textFieldWithWidth:150
                                                     height:50 text:@"Current BPS:"];
    bpsLabel.x = gameWidth/2 - bpsLabel.width;
    bpsLabel.y = y_offset + 5;
    bpsLabel.fontSize = 20;
    bpsLabel.hAlign = SPHAlignRight;
    //bpsLabel.border = YES;
    [self addChild:bpsLabel];
    
    // quit button
    SPTexture *closeTexture = [SPTexture textureWithContentsOfFile:@"close.png"];
    SPButton *quitButton = [SPButton buttonWithUpState:closeTexture];
    quitButton.x = 0;
    quitButton.y = 0;
    quitButton.scaleX = 1.3;
    quitButton.scaleY = 1.3;
    [self addChild:quitButton];
    [quitButton addEventListener:@selector(quitRace) atObject:self forType:SP_EVENT_TYPE_TRIGGERED];
    
    // Auto start
    [self addEventListener:@selector(restartRace) atObject:self forType:SP_EVENT_TYPE_ADDED_TO_STAGE];
    
    // Update BPS meter
    [self addEventListener:@selector(enterFrame:) atObject:self forType:SP_EVENT_TYPE_ENTER_FRAME];
    
    // Instruction close
    [self addEventListener:@selector(raceWillStart) atObject:self forType:SP_EVENT_TYPE_SCENE_CLOSE];
}


- (void)dealloc {
    [self removeEventListenersAtObject:self forType:SP_EVENT_TYPE_ENTER_FRAME];
    [self removeEventListenersAtObject:self forType:SP_EVENT_TYPE_ADDED_TO_STAGE];
    [_canvas removeEventListenersAtObject:self forType:SP_EVENT_TYPE_TOUCH];
}


- (void)restartRace {
    Userdata *ud = [[GlobalStorage sharedInstance] activeUserdata];
    
    // Show instruction in the 1st time.
    if (ud.experience == 0.0) {
        _targetLabel.text = @"a";
        _targetLabel.x = _targetLabelCenter.x;
        _targetLabel.y = _targetLabelCenter.y;
        if (Sparrow.stage.height > 480) {
            InstructionScene *instruction = [[InstructionScene alloc]
                                             initWithImageName:@"race-instruction-568.png"];
            [self addChild:instruction];
        }
        else {
            InstructionScene *instruction = [[InstructionScene alloc]
                                             initWithImageName:@"race-instruction.png"];
            [self addChild:instruction];
        }
    }
    else {
        // Check for new prototypes from server
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:Sparrow.currentController.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Checking prototypes...";
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            NSDictionary *protosets = [ServerManager fetchProtosets:ud.userID];
            if (protosets) {
                // Count prototypes
                NSMutableArray *updatedLabels = [[NSMutableArray alloc] init];
                for (id key in _activeCharacters) {
                    Protoset *old_ps = ud.protosets[key];
                    Protoset *new_ps = protosets[key];
                    if (old_ps && new_ps && new_ps.protosetID > old_ps.protosetID) {
                        [updatedLabels addObject:key];
                    }
                    else if (!old_ps && new_ps) {
                        [updatedLabels addObject:key];
                    }
                }
                
                // New prototypes found, update and notify user
                if ([updatedLabels count] > 0) {
                    
                    // Update the protosets
                    [ud setProtosets:protosets];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        hud.labelText = [NSString stringWithFormat:@"%d characters updated.",
                                         [updatedLabels count]];
                        [Sparrow.juggler delayInvocationByTime:1.5 block:^{
                            [hud hide:YES];
                            [self raceWillStart];
                        }];
                    });
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [hud hide:YES];
                        [self raceWillStart];
                    });
                }
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hide:YES];
                    [self raceWillStart];
                });
            }
        });
    }
}


- (void)raceWillStart {
    Userdata *ud = [[GlobalStorage sharedInstance] activeUserdata];
   
    // Setting up classifier
    NSArray *prototypes = [ud prototypesWithLabels:_activeCharacters];
    _classifier = [[BFClassifier alloc] initWithPrototypes:prototypes
                                                      mode:_classifierMode];
    [_classifier setDelegate:self];
    [_canvas setClassifier:_classifier];
    
    // Create a new session
    _session = [[SessionData alloc] init];
    _session.userID = ud.userID;
    _session.modeID = _modeID;
    
    // Create test array
    _testArray = [self shuffleArray:_activeCharacters maxLength:RACE_LENGTH];
    
    _session.activeCharacters = _activeCharacters;
    _session.activeProtosetIDs = [ud protosetIDsWithLabels:_activeCharacters];
    
    // Reset stats
    _currentIdx = 0;
    _totalScore = 0;
    _totalTime = 0;
    
    // BPS meter
    _bpsTextField.text = @"0.00";
    
    // Target character
    _targetLabel.text = @"";
    
    [_canvas clear];
    _canvas.touchable = NO;
    
    // Start count down
    [self countDown];
}


- (void)countDown {
    SPTextField *countdown = [[SPTextField alloc] initWithWidth:120 height:120];
    countdown.hAlign = SPHAlignCenter;
    countdown.vAlign = SPVAlignCenter;
    countdown.pivotX = countdown.width/2;
    countdown.pivotY = countdown.height/2;
    countdown.x = _canvas.x + _canvas.width/2;
    countdown.y = _canvas.y + _canvas.height/2;
    countdown.color = 0xffffff;
    countdown.fontName = @"Chalkduster";
    countdown.fontSize = 120;
    //banner.border = YES;
    [self addChild:countdown];
    
    [[Sparrow juggler] delayInvocationByTime:0.25f block:^{
        countdown.text = @"3";
        [Media playSound:@"WhoopFlp.caf"];
    }];
    
    [[Sparrow juggler] delayInvocationByTime:1.25f block:^{
        countdown.text = @"2";
        [Media playSound:@"WhoopFlp.caf"];
    }];
    
    [[Sparrow juggler] delayInvocationByTime:2.25f block:^{
        countdown.text = @"1";
        [Media playSound:@"WhoopFlp.caf"];
    }];
    
    [[Sparrow juggler] delayInvocationByTime:3.25f block:^{
        [self removeChild:countdown];
        [self startRound];
    }];
}


- (void)startRound {
    _roundTime = 0.0;
    
    _earlyStopFound = NO;
    
    _round = [[RoundData alloc] init];
    _round.startTime = [NSDate timeIntervalSinceReferenceDate];
    
    NSString *currentLabel = _testArray[_currentIdx];
    
    _bar.width = _canvas.width;
    
    _targetLabel.text = currentLabel;
    _targetLabel.x = _canvas.x + _canvas.width/2;
    _targetLabel.y = _canvas.y + _canvas.height/2;
    _targetLabel.scaleX = 2.0;
    _targetLabel.scaleY = 2.0;
    SPTween *targetAnimate = [SPTween tweenWithTarget:_targetLabel time:0.5
                              transition:SP_TRANSITION_EASE_IN];
    targetAnimate.delay = 0.1;
    [targetAnimate animateProperty:@"scaleX" targetValue:1.0];
    [targetAnimate animateProperty:@"scaleY" targetValue:1.0];
    [targetAnimate animateProperty:@"x" targetValue:_targetLabelCenter.x];
    [targetAnimate animateProperty:@"y" targetValue:_targetLabelCenter.y];
    [Sparrow.juggler addObject:targetAnimate];
    
    [Media playSound:[[NSString stringWithFormat:@"%@.caf", currentLabel]
                      lowercaseString]];
    
    
    [_classifier setTargetLabel:_targetLabel.text];
    [_canvas clear];
    _canvas.touchable = YES;
}


- (void)endRound {
    _canvas.touchable = NO;
    
    [Media playSound:@"DING.caf"];
    
    _round.firstPendownTime = _canvas.firstTouchTime;
    _round.lastPenupTime = _canvas.lastTouchTime;
    _round.score = _currentScore;
    _round.ink = _canvas.currentInkCharacter;
    _round.label = _targetLabel.text;
    _round.result = [[ClassificationResult alloc]
                     initWithDictionary:[_classifier posterior]];
    
    [_session addRound:_round];
    
    float delta_time = _round.lastPenupTime - _round.startTime;
    _totalScore += _currentScore;
    _totalTime += delta_time;
    
    SPTextField *popupScore = [SPTextField textFieldWithText:[NSString
                                                              stringWithFormat:@"+%0.2f bits",_currentScore]];
    popupScore.width = 250;
    popupScore.x = 100;
    popupScore.y = 140;
    popupScore.fontSize = 30;
    float maxscore = log2f([_activeCharacters count]);
    if (_currentScore >  maxscore - 1.0) {
        popupScore.color = 0x149005;
    } else if (_currentScore > maxscore / 2) {
        popupScore.color = 0xf08b19;
    } else {
        popupScore.color = 0xff0000;
    }
    popupScore.alpha = 1.0;
    [self addChild:popupScore];
    SPTween *tween = [SPTween tweenWithTarget:popupScore
                                         time:1.4f];
    tween.delay = 0.1;
    tween.onComplete = ^{ [self removeChild:popupScore]; };
    [tween animateProperty:@"y" targetValue:50];
    [tween animateProperty:@"alpha" targetValue:0.0];
    [[Sparrow juggler] addObject:tween];

    _currentIdx++;
    if (_currentIdx < [_testArray count]) {
        [self startRound];
    } else {
        [self raceCompleted];
    }
}


- (void)raceCompleted {
    _canvas.touchable = NO;
    [_canvas clear];

    _bpsTextField.text = @"";
    _targetLabel.text = @"";
    
    _session.totalScore = _totalScore;
    _session.totalTime = _totalTime;
    _session.bps = _totalScore / _totalTime;
    
    _totalScore = 0;
    _totalTime = 0;
    
    Userdata *ud = [[GlobalStorage sharedInstance] activeUserdata];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        bool sentOK = [ServerManager uploadSessionData:_session];
        if (sentOK) {
            // Try to send other stored sessions as well.
            while ([ud.sessions count] > 0) {
                SessionData *ses = [[SessionData alloc] initWithJSONObject:[ud.sessions lastObject]];
                if ([ServerManager uploadSessionData:ses]) {
                    [ud.sessions removeLastObject];
                } else {
                    break;
                }
            }
        } else {
            [ud addSessionJSON:[_session toJSONObject]];
        }
    });
    
    RaceSummaryScene *summary = [[RaceSummaryScene alloc] initWithSession:_session];
    [summary addEventListenerForType:SP_EVENT_TYPE_QUIT_RACE block:^(id event){
        [self quitRace];
    }];
    [summary addEventListenerForType:SP_EVENT_TYPE_RESTART_RACE block:^(id event){
        [self restartRace];
    }];
    
    [Sparrow.juggler delayInvocationByTime:0.01f block:^{
        [summary dropFromTop];
        [self addChild:summary];
    }];
}


- (void)reset {
    [_canvas clear];
    _earlyStopFound = NO;
    [Sparrow.juggler removeObjectsWithTarget:_bar];
    _bar.width = _canvas.width;
}


- (void)enterFrame:(SPEnterFrameEvent *)event {
    static double ticks;
    static double milliseconds;
    ticks += event.passedTime;
    // Update every 0.1 second
    if (floor(ticks*100) > milliseconds) {
        milliseconds += 10;
        _roundTime += event.passedTime;
        float bps = _totalScore / (_totalTime + _roundTime);
        _bpsTextField.text = [NSString stringWithFormat:@"%0.2f", bps];
    }
}


- (void)quitRace {
    [Sparrow.juggler removeAllObjects];
    [self removeFromParent];
}


- (void)thresholdReached:(InkPoint *)point {
    if (!_earlyStopFound) {
        [_canvas drawMarkerAt:point];
        _earlyStopFound = YES;
        [Media playSound:@"tick.caf"];
    }
}


- (void)updateScore:(float)targetProb {
    float p = 1.0 / targetProb;
    _currentScore = MAX(log2f([_activeCharacters count]) - log2f(p), 0);
}


- (void)onTouch:(SPTouchEvent *)event {
    [Sparrow.juggler removeObjectsWithTarget:_bar];
    _bar.width = _canvas.width;
    SPTouch *touchEnd = [[event touchesWithTarget:self andPhase:SPTouchPhaseEnded] anyObject];
    if (touchEnd){
        SPTween *shinking = [[SPTween alloc] initWithTarget:_bar time:WAIT_TIME];
        [shinking animateProperty:@"width" targetValue:0];
        shinking.onComplete = ^{ [self endRound]; };
        [Sparrow.juggler addObject:shinking];
    }
}


- (NSArray *)shuffleArray:(NSArray *)labels maxLength:(int)length {
    NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:labels];
    for (NSInteger i = [labels count] - 1, j; i >= 0; i--)
    {
        j = arc4random() % (i + 1);
        
        NSString *buffer = temp[i];
        temp[i] = temp[j];
        temp[j] = buffer;
    }
    NSMutableArray *outArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < MIN([labels count], length); i++) {
        [outArray addObject:temp[i]];
    }
    return outArray;
}

@end
