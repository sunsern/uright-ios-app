//
//  Media.h
//  AppScaffold
//

#import <Foundation/Foundation.h>

@interface Media : NSObject 

+ (void)initSound;
+ (void)releaseSound;

+ (SPSoundChannel *)soundChannel:(NSString *)soundName;
+ (void)playSound:(NSString *)soundName;

@end
