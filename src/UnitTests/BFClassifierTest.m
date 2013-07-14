//
//  BFClassifierTest.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/12/13.
//
//

#import "BFClassifierTest.h"

#import "BFClassifier.h"
#import "GlobalStorage.h"
#import "UserStorage.h"
#import "ServerManager.h"
#import "InkPoint.h"

@implementation BFClassifierTest {
    BFClassifier *_classifier;
    float _lastScore;
}

- (void)thresholdReached:(InkPoint *)point {
    // Do nothing
}

- (void)updateScore:(float)v {
    _lastScore = v;
}

- (void)setUp
{
    [super setUp];
    
    // Initialize the singleton storage
    GlobalStorage *gs = [GlobalStorage sharedInstance];
    [gs loadGlobalData];
    [gs loadUserData];
    UserStorage *us = [gs userdata];
    _classifier = [us classifier];
    [_classifier setDelegate:self];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    _classifier = nil;
    
    [super tearDown];
}

- (void)testSimple
{
    [_classifier setTargetLabel:@"a"];
    [_classifier reset];
    
    [_classifier addPoint:[[InkPoint alloc] initWithX: 0.77 y:0.20]];
    [_classifier addPoint:[[InkPoint alloc] initWithX: 0.50 y:0.02]];
    [_classifier addPoint:[[InkPoint alloc] initWithX: 0.23 y:0.00]];
    [_classifier addPoint:[[InkPoint alloc] initWithX:-0.17 y:0.00]];
    [_classifier addPoint:[[InkPoint alloc] initWithX:-0.54 y:0.18]];
    [_classifier addPoint:[[InkPoint alloc] initWithX:-0.75 y:0.41]];
    [_classifier addPoint:[[InkPoint alloc] initWithX:-0.84 y:0.59]];
    [_classifier addPoint:[[InkPoint alloc] initWithX:-0.84 y:0.74]];
    [_classifier addPoint:[[InkPoint alloc] initWithX:-0.82 y:0.81]];
    [_classifier addPoint:[[InkPoint alloc] initWithX:-0.49 y:0.81]];
    [_classifier addPoint:[[InkPoint alloc] initWithX:-0.08 y:0.55]];
    [_classifier addPoint:[[InkPoint alloc] initWithX: 0.22 y:0.40]];
    [_classifier addPoint:[[InkPoint alloc] initWithX: 0.37 y:0.35]];
    [_classifier addPoint:[[InkPoint alloc] initWithX: 0.44 y:0.35]];
    [_classifier addPoint:[[InkPoint alloc] initWithX: 0.49 y:0.44]];
    [_classifier addPoint:[[InkPoint alloc] initWithX: 0.58 y:0.78]];
    [_classifier addPoint:[[InkPoint alloc] initWithX: 0.90 y:1.00]];
    
    [_classifier addPoint:[InkPoint penupPoint]];
    
    [NSThread sleepForTimeInterval:1.5];
    //while (true) {}
    
    STAssertTrue(_lastScore > 0.9f, @"Probability too low");
    
}


@end
