//
//  AppDelegate.m
//  AppScaffold
//
#import <Parse/Parse.h>

#import "AppDelegate.h"
#import "Game.h"
#import "GlobalStorage.h"

// --- c functions ---

void onUncaughtException(NSException *exception)
{
    NSLog(@"uncaught exception: %@", exception.description);
}

// ---

@implementation AppDelegate
{
    SPViewController *_viewController;
    UIWindow *_window;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSSetUncaughtExceptionHandler(&onUncaughtException);
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    _window = [[UIWindow alloc] initWithFrame:screenBounds];
    
    _viewController = [[SPViewController alloc] init];
    
    // Parse
    [Parse setApplicationId:@"ZipLoxI33o1cT0tNlyxno0nXE9o1EaTGfVEgmKjF"
                  clientKey:@"QrZmj7ADH1cRXMbJpYaNtNPvg5xjP16J8bPn6CUJ"];
    
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    // Enable FB
    [PFFacebookUtils initializeFacebook];
    
    
    [PFTwitterUtils initializeWithConsumerKey:@"mZ9gPegAV4CSb3uLXRTUxg"
                               consumerSecret:@"mOp9ro4wgRVo6ehsxrt4y5zrkBG4AXsVbToDQantSAU"];
    
    
    // Initialize the singleton storage
    [GlobalStorage sharedInstance];
        
    // Enable some common settings here:
    //
    // _viewController.showStats = YES;
    // _viewController.multitouchEnabled = YES;
     _viewController.preferredFramesPerSecond = 60;
    
    // Let's disable multitouch
    _viewController.multitouchEnabled = NO;
    
    [_viewController startWithRoot:[Game class] supportHighResolutions:YES doubleOnPad:YES];
    
    [_window setRootViewController:_viewController];
    [_window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Commit changes to disk
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    return [PFFacebookUtils handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [PFFacebookUtils handleOpenURL:url];
}

@end
