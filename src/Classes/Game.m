//
//  Game.m
//  AppScaffold
//

#import "Game.h" 
#import "Canvas.h"
#import "MenuScene.h"
#import "RaceScene.h"
#import "ServerManager.h"

@implementation Game
{
    SPSprite *_contents;
    SPSprite *_currentScene;
}

- (id)init
{
    if ((self = [super init]))
    {
        [self setup];
    }
    return self;
}

- (void)dealloc
{
    // release any resources here
    [Media releaseAtlas];
    [Media releaseSound];
}

- (void)setup
{
    // This is where the code of your game will start. 
    // In this sample, we add just a few simple elements to get a feeling about how it's done.
    
    [SPAudioEngine start];  // starts up the sound engine
    
    
    // The Application contains a very handy "Media" class which loads your texture atlas
    // and all available sound files automatically. Extend this class as you need it --
    // that way, you will be able to access your textures and sounds throughout your 
    // application, without duplicating any resources.
    
    [Media initAtlas];      // loads your texture atlas -> see Media.h/Media.m
    [Media initSound];      // loads all your sounds    -> see Media.h/Media.m
    
    
    // Create some placeholder content: a background image, the Sparrow logo, and a text field.
    // The positions are updated when the device is rotated. To make that easy, we put all objects
    // in one sprite (_contents): it will simply be rotated to be upright when the device rotates.

    _contents = [SPSprite sprite];
    [self addChild:_contents];
    
    [self updateLocations];
    
    
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
    
    //MenuScene *menu = [[MenuScene alloc] init];
    //[self showScene:menu];
    
    
    [[Sparrow juggler] delayInvocationByTime:0.5f block:^{
        RaceScene *race = [[RaceScene alloc] init];
        [self showScene:race];
    }];
    
    /*
    // play a sound when the image is touched
    [image addEventListener:@selector(onImageTouched:) atObject:self forType:SP_EVENT_TYPE_TOUCH];
    
    // and animate it a little
    SPTween *tween = [SPTween tweenWithTarget:image time:1.5 transition:SP_TRANSITION_EASE_IN_OUT];
    [tween animateProperty:@"y" targetValue:image.y + 30];
    [tween animateProperty:@"rotation" targetValue:0.1];
    tween.repeatCount = 0; // repeat indefinitely
    tween.reverse = YES;
    [Sparrow.juggler addObject:tween];
    */

    // The controller autorotates the game to all supported device orientations. 
    // Choose the orienations you want to support in the Xcode Target Settings ("Summary"-tab).
    // To update the game content accordingly, listen to the "RESIZE" event; it is dispatched
    // to all game elements (just like an ENTER_FRAME event).
    // 
    // To force the game to start up in landscape, add the key "Initial Interface Orientation"
    // to the "App-Info.plist" file and choose any landscape orientation.
    
    [self addEventListener:@selector(onResize:) atObject:self forType:SP_EVENT_TYPE_RESIZE];
}

- (void)updateLocations
{
    int gameWidth  = Sparrow.stage.width;
    int gameHeight = Sparrow.stage.height;
    
    //_contents.x = (int) (gameWidth  - _contents.width)  / 2;
    //_contents.y = (int) (gameHeight - _contents.height) / 2;
    
    NSLog(@"%f %f", _contents.width, _contents.height);
    NSLog(@"%d %d", gameWidth, gameHeight);
    
}

- (void)onResize:(SPResizeEvent *)event
{
    NSLog(@"new size: %.0fx%.0f (%@)", event.width, event.height, 
          event.isPortrait ? @"portrait" : @"landscape");
    
    [self updateLocations];
}

- (void)showScene:(SPSprite *)scene {
    if ([_contents containsChild:_currentScene]) {
        [_contents removeChild:_currentScene];
    }
    [_contents addChild:scene];
    _currentScene = scene;
    [self updateLocations];
}

@end
