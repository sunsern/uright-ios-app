//
//  RaceScene.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/5/13.
//
//

#import "Scene.h"
#import "BFClassifier.h"

@interface RaceScene : Scene <BFClassifierDelegate>

- (id)initWithCharacters:(NSArray *)characters
          classifierMode:(BFClassifierMode)classifierMode
                  modeID:(int)modeID;

@end
