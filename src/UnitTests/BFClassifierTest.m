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
    NSLog(@"YOY");
}

- (void)setUp
{
    [super setUp];
    
    // Initialize the singleton storage
    GlobalStorage *gs = [GlobalStorage sharedInstance];
    [gs loadData];
    
    // build cache
    UserStorage *us = [gs userdata];
    [us switchToLanguageId:[us languageId]];
    
    // Auto login
    NSDictionary *jsonObj = [ServerManager fetchDataForUsername:@"sunsern"
                                                       password:@"12345"];
    // update user-independent data
    if (jsonObj != nil) {
        GlobalStorage *gs = [GlobalStorage sharedInstance];
        [gs setLanguages:[jsonObj objectForKey:@"languages"]];
        
        // now user-specific data
        NSString *login_result = [jsonObj objectForKey:@"login_result"];
        if ([login_result isEqualToString:@"OK"]) {
            int newUserId = [[jsonObj objectForKey:@"user_id"] intValue];
            // switch user and save data
            [gs switchToUser:newUserId];
            // Update classifier with the new one
            UserStorage *us = [gs userdata];
            [us setClassifiers:[[NSMutableDictionary alloc]
                                initWithDictionary:[jsonObj objectForKey:@"classifiers"]]];
            [us setUsername:@"sunsern"];
            [us setPassword:@"12345"];
            [us switchToLanguageId:[us languageId]];
            [gs saveUserData];
            
        } else {
            // save the langauges data
            [gs saveGlobalData];
        }
    }

    _classifier = [[BFClassifier alloc] initWithExampleSet:[us exampleSet]];
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
    
    STAssertTrue(_lastScore > 0.9f, @"Probability too low");
    
}


@end
