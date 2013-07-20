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

@implementation RaceSummaryScene {
    SessionData *_session;
}

- (id)initWithSession:(SessionData *)session {
    self = [super init];
    if (self) {
        int gameWidth = Sparrow.stage.width;
        int gameHeight = Sparrow.stage.height;
        
        _session = session;
        
        // Window
        SPQuad *window = [SPQuad quadWithWidth:gameWidth height:gameHeight color:0xcccccc];
        window.x = (gameWidth - window.width) / 2;
        window.y = (gameHeight - window.height) / 2;
        [self addChild:window];
        

        // Session Summary
        SPTextField *summary_banner = [SPTextField textFieldWithWidth:window.width
                                                               height:100
                                                                 text:@"Summary"
                                                             fontName:@"Papyrus"
                                                             fontSize:50
                                                                color:0x000000];
        summary_banner.x = (gameWidth - summary_banner.width) / 2;
        summary_banner.y = window.y + 10;
        //summary_banner.border = YES;
        [self addChild:summary_banner];
        
        NSString *summary = [NSString stringWithFormat:
                             @"Total score:\n"
                             "%0.2f\n\n"
                             "Total time:\n"
                             "%0.2f\n\n"
                             "BPS:\n"
                             "%0.2f\n\n",
                             session.totalScore, session.totalTime, session.bps];
        
        SPTextField *session_summary = [SPTextField textFieldWithWidth:window.width
                                                                height:300
                                                                  text:summary
                                                              fontName:@"ArialMT"
                                                              fontSize:25
                                                                 color:0x000000];
        session_summary.y = summary_banner.y + summary_banner.height;
        //session_summary.border = YES;
        session_summary.autoScale = YES;
        session_summary.vAlign = SPVAlignCenter;
        [self addChild:session_summary];
        
        // Restart button
        SPTexture *buttonTexture = [SPTexture textureWithContentsOfFile:@"button_big.png"];
        SPButton *restartButton = [SPButton buttonWithUpState:buttonTexture text:@"Restart"];
        restartButton.x = gameWidth / 2 - restartButton.width - 5;
        restartButton.y = gameHeight - restartButton.height - 50;
        [self addChild:restartButton];
        [restartButton addEventListener:@selector(restartRace)
                               atObject:self
                                forType:SP_EVENT_TYPE_TRIGGERED];
        
        // Quit button
        SPButton *okButton = [SPButton buttonWithUpState:buttonTexture text:@"Quit"];
        okButton.x = gameWidth / 2 + 5;
        okButton.y = gameHeight - okButton.height - 50;
        [self addChild:okButton];
        [okButton addEventListener:@selector(quitRace)
                               atObject:self
                                forType:SP_EVENT_TYPE_TRIGGERED];
    }
    return self;
}


- (void)quitRace {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [ServerManager uploadSessionData:_session];
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self dispatchEventWithType:SP_EVENT_TYPE_QUIT_RACE];
            [self removeFromParent];
        });
    });
}

- (void)restartRace {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [ServerManager uploadSessionData:_session];
        dispatch_async(dispatch_get_main_queue(), ^ {
            [self dispatchEventWithType:SP_EVENT_TYPE_RESTART_RACE];
            [self shootUpAndClose];
        });
    });
}

@end
