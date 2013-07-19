//
//  Game.m
//  AppScaffold
//

#import "Game.h" 
#import "MenuScene.h"
#import "AccountManager.h"

@implementation Game
{
    SPSprite *_mainmenu;
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
    
    // Initialize the singleton storage
    //[GlobalStorage clearGlobalData];
    [GlobalStorage sharedInstance];

    // Initialize Facebook session
    [AccountManager initializeFacebookSession];
    
    _mainmenu = [[MenuScene alloc] init];
    [self addChild:_mainmenu];
    
    [self updateLocations];
    
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
    //int gameWidth  = Sparrow.stage.width;
    //int gameHeight = Sparrow.stage.height;
    
    //_contents.x = (int) (gameWidth  - _contents.width)  / 2;
    //_contents.y = (int) (gameHeight - _contents.height) / 2;
}

- (void)onResize:(SPResizeEvent *)event
{
    NSLog(@"new size: %.0fx%.0f (%@)", event.width, event.height, 
          event.isPortrait ? @"portrait" : @"landscape");
    
    [self updateLocations];
}

@end
