//
//  RaceSummaryScene.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/19/13.
//
//

#import "Scene.h"

#define SP_EVENT_TYPE_RESTART_RACE @"race_restart"
#define SP_EVENT_TYPE_QUIT_RACE @"race_quit"

@interface RaceSummaryScene : Scene

- (id)initWithSession:(SessionData *)session;


@end
