//
//  RaceSummaryScene.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/19/13.
//
//

#import "RaceSummaryScene.h"

#import "SessionData.h"
#import "ServerManager.h"
#import "RaceReviewScene.h"
#import "RoundData.h"
#import "ClassificationResult.h"

@implementation RaceSummaryScene {
    SessionData *_session;
}

- (id)initWithSession:(SessionData *)session {
    self = [super init];
    if (self) {
        int gameWidth = Sparrow.stage.width;
        int gameHeight = Sparrow.stage.height;
        int y_offset = 0;
        
        if (gameHeight > 480) {
            y_offset = 44;
        }
        
        _session = session;
        
        // Background
        SPImage *background = [SPImage imageWithContentsOfFile:@"background-orange-pine.png"];
        [self addChild:background];
        
        // Window
        SPQuad *window = [SPQuad quadWithWidth:gameWidth height:gameHeight color:0x000000];
        window.x = (gameWidth - window.width) / 2;
        window.y = (gameHeight - window.height) / 2;
        window.alpha = 0.0;
        [self addChild:window];
        

        // Session Summary
        SPTextField *summary_banner = [SPTextField textFieldWithWidth:window.width-40
                                                               height:75
                                                                 text:@"Summary"
                                                             fontName:@"Chalkduster"
                                                             fontSize:48
                                                                color:0x000000];
        summary_banner.x = (gameWidth - summary_banner.width) / 2;
        summary_banner.y = y_offset + window.y + 20;
        summary_banner.autoScale = YES;
        [self addChild:summary_banner];
        
        NSString *summary = [NSString stringWithFormat:
                             @"Total bits:  %0.2f\n\n"
                             "Total time:  %0.2f\n\n"
                             "BPS:  %0.2f\n\n"
                             "Experience: %0.2f",
                             session.totalScore, session.totalTime, session.bps, session.bps];
        
        SPTextField *session_summary = [SPTextField textFieldWithWidth:window.width-40
                                                                height:300
                                                                  text:summary
                                                              fontName:@"MarkerFelt-Wide"
                                                              fontSize:24
                                                                 color:0x000000];
        session_summary.x = (gameWidth - session_summary.width) / 2;
        session_summary.y = summary_banner.y + summary_banner.height;
        //session_summary.border = YES;
        session_summary.autoScale = YES;
        session_summary.vAlign = SPVAlignCenter;
        [self addChild:session_summary];
        
        // Close button
        SPTexture *closeTexture = [SPTexture textureWithContentsOfFile:@"close.png"];
        SPButton *closeButton = [SPButton buttonWithUpState:closeTexture];
        closeButton.x = 0;
        closeButton.y = 0;
        closeButton.scaleX = 1.3;
        closeButton.scaleY = 1.3;
        [self addChild:closeButton];
        [closeButton addEventListener:@selector(quitRace) atObject:self
                              forType:SP_EVENT_TYPE_TRIGGERED];

        // Restart button
        SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big.png"];
        SPButton *restartButton = [SPButton buttonWithUpState:buttonTexture text:@"Restart Race"];
        restartButton.pivotX = restartButton.width / 2;
        restartButton.pivotY = restartButton.height / 2;
        restartButton.x = gameWidth/4;
        restartButton.y = session_summary.y + session_summary.height + 30;
        restartButton.scaleX = 1.1;
        restartButton.scaleY = 1.1;
        restartButton.fontName = @"Chalkduster";
        [self addChild:restartButton];
        [restartButton addEventListener:@selector(restartRace) atObject:self
                                forType:SP_EVENT_TYPE_TRIGGERED];
        
        // Review button
        SPButton *reviewButton = [SPButton buttonWithUpState:buttonTexture text:@"Review"];
        reviewButton.pivotX = reviewButton.width / 2;
        reviewButton.pivotY = reviewButton.height / 2;
        reviewButton.x = 3*gameWidth/4;
        reviewButton.y = session_summary.y + session_summary.height + 30;
        reviewButton.scaleX = 1.1;
        reviewButton.scaleY = 1.1;
        reviewButton.fontName = @"Chalkduster";
        [self addChild:reviewButton];
        [reviewButton addEventListener:@selector(review) atObject:self
                               forType:SP_EVENT_TYPE_TRIGGERED];
        
        // Count mistakes and disable review button
        int mistake_count = 0;
        for (RoundData *rd in session.rounds) {
            NSString *trueLabel = rd.label;
            NSString *predicted = [rd.result predictionByRanking:0];
            if (predicted && ![trueLabel isEqualToString:predicted]) {
                mistake_count++;
            }
        }
        if (mistake_count == 0) {
            reviewButton.enabled = NO;
        }
    }
    return self;
}


- (void)review {
    RaceReviewScene *review = [[RaceReviewScene alloc] initWithSessionData:_session];
    [review dropFromTopNoBounce];
    [self addChild:review];
}

- (void)quitRace {
    [self dispatchEventWithType:SP_EVENT_TYPE_QUIT_RACE];
    [self removeFromParent];
}

- (void)restartRace {
    [self dispatchEventWithType:SP_EVENT_TYPE_RESTART_RACE];
    [self shootUpAndClose];
}

@end
