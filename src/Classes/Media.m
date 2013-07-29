//
//  Media.m
//  AppScaffold
//

#import "Media.h"


@implementation Media

static NSMutableDictionary *sounds = NULL;
static NSDictionary *asciiNameDB = NULL;

#pragma mark Audio

+ (void)initSound
{
    if (sounds) return;
    
    [SPAudioEngine start];
    sounds = [[NSMutableDictionary alloc] init];
    
    // enumerate all sounds
    
    NSString *soundDir = [[NSBundle mainBundle] resourcePath];    
    NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:soundDir];   
    
    NSString *filename;
    while (filename = [dirEnum nextObject]) 
    {
        if ([[filename pathExtension] isEqualToString: @"caf"])
        {
            SPSound *sound = [[SPSound alloc] initWithContentsOfFile:filename];            
            sounds[filename] = sound;
        }
    }
    
    asciiNameDB = @{@"א.caf" : @"alef.caf",
                    @"ב.caf" : @"bet.caf",
                    @"ג.caf" : @"gimel.caf",
                    @"ד.caf" : @"dalet.caf",
                    @"ה.caf" : @"he.caf",
                    @"ו.caf" : @"vav.caf",
                    @"ז.caf" : @"zayin.caf",
                    @"ח.caf" : @"het.caf",
                    @"ט.caf" : @"tet.caf",
                    @"י.caf" : @"yod.caf",
                    @"כ.caf" : @"kaf.caf",
                    @"ל.caf" : @"lamed.caf",
                    @"מ.caf" : @"mem.caf",
                    @"נ.caf" : @"nun.caf",
                    @"ס.caf" : @"samekh.caf",
                    @"ע.caf" : @"ayin.caf",
                    @"פ.caf" : @"pe.caf",
                    @"צ.caf" : @"tsadi.caf",
                    @"ק.caf" : @"qof.caf",
                    @"ר.caf" : @"resh.caf",
                    @"ש.caf" : @"shin.caf",
                    @"ת.caf" : @"tav.caf",
                    @"ם.caf" : @"mem_final.caf",
                    @"ן.caf" : @"nun_final.caf",
                    @"ף.caf" : @"pe_final.caf",
                    @"ך.caf" : @"kaf_final.caf",
                    @"ץ.caf" : @"tsadi_final.caf"};
    
}

+ (void)releaseSound
{
    sounds = nil;
    
    [SPAudioEngine stop];
}

+ (void)playSound:(NSString *)soundName
{
    if (asciiNameDB[soundName] != nil) {
        soundName = asciiNameDB[soundName];
    }
    
    SPSound *sound = sounds[soundName];

    if (sound)
        [sound play];
    //else
    //    [[SPSound soundWithContentsOfFile:soundName] play];
}

+ (SPSoundChannel *)soundChannel:(NSString *)soundName
{
    SPSound *sound = sounds[soundName];
    
    // sound was not preloaded
    if (!sound)        
        sound = [SPSound soundWithContentsOfFile:soundName];
    
    return [sound createChannel];
}

@end
