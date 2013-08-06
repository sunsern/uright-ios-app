//
//  Game.m
//  AppScaffold
//

#import "Game.h" 
#import "MenuScene.h"
#import "AccountManager.h"
#import "GlobalStorage.h"

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
    
    [Media initSound];      // loads all your sounds    -> see Media.h/Media.m
    
    // Initialize the singleton storage
    [GlobalStorage sharedInstance];
    
    _mainmenu = [[MenuScene alloc] init];
    [self addChild:_mainmenu];
}

@end
