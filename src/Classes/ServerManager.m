//
//  ServerManager.m
//  Handwriting
//
//  Created by Sunsern Cheamanunkul on 6/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ServerManager.h"

#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "SessionData.h"
#import "ExampleSet.h"
#import "Reachability.h"
#import <CommonCrypto/CommonDigest.h>

@implementation ServerManager

+ (void)showConnectionError:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}

+ (BOOL)isOnline {
    NetworkStatus internetStatus = [[Reachability reachabilityForInternetConnection]
                                    currentReachabilityStatus];
    return (internetStatus != NotReachable);
}

+ (NSDictionary *)fetchDataForUsername:(NSString *)username
                              password:(NSString *)password  {
    const char *cStr = [password UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *hashed = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [hashed appendFormat:@"%02x", digest[i]];

    NSString *urlString = [NSString stringWithFormat:@"%@cgi/getuserdata.php", kBaseURL];
    urlString = [urlString stringByAppendingString:@"?key=iosexp2"];
    urlString = [urlString stringByAppendingFormat:@"&username=%@", username];
    urlString = [urlString stringByAppendingFormat:@"&password=%@", hashed];
    NSURL *url = [NSURL URLWithString:urlString];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request startSynchronous];
    if ([request error] != nil) {
        return nil;
    }
    
    NSError *error;
    //NSLog(@"%@",[request responseString]);
    return [NSJSONSerialization JSONObjectWithData:[request responseData]
                                           options:kNilOptions
                                             error:&error];
}

+ (NSDictionary *)submitSessionData:(SessionData *)data {
    if ([data examplesCount] > 0) {
        NSString *urlString = [NSString stringWithFormat:@"%@cgi/submit_session.php?key=iosexp2", kBaseURL];
        NSURL *url = [NSURL URLWithString:urlString];
        ASIFormDataRequest  *request = [ASIFormDataRequest requestWithURL:url];
        
        NSString *jsonString = [[NSString alloc] initWithData:[data examplesJSONData]
                                                     encoding:NSUTF8StringEncoding];
        [request setPostValue:jsonString forKey:@"collected_data_json"];
        [request setPostValue:[NSString stringWithFormat:@"%d", data.userId]
                       forKey:@"user_id"];
        [request setPostValue:[NSString stringWithFormat:@"%d", data.modeId]
                       forKey:@"mode_id"];
        [request setPostValue:[NSString stringWithFormat:@"%d", data.classifierId]
                       forKey:@"classifier_id"];
        [request setPostValue:[NSString stringWithFormat:@"%f", data.startTime]
                       forKey:@"start_time"];
        [request setPostValue:[NSString stringWithFormat:@"%f", data.endTime]
                       forKey:@"end_time"];
        [request setPostValue:[NSString stringWithFormat:@"%d", data.languageId]
                       forKey:@"language_id"];
        [request setPostValue:[NSString stringWithFormat:@"%f", data.bps]
                       forKey:@"bps"];
        [request startSynchronous];
        
        if ([request error] != nil) {
            return nil;
        }
        
        NSError *error;
        return [NSJSONSerialization JSONObjectWithData:[request responseData]
                                               options:kNilOptions
                                                 error:&error];
    }
    return nil;
}



- (void)synchronizeData {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please wait"
                                                    message:@"Synchronizing data..."
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:nil];
    [alert show];
    if(alert != nil) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        indicator.center = CGPointMake(alert.bounds.size.width/2, alert.bounds.size.height-45);
        [indicator startAnimating];
        [alert addSubview:indicator];
    }
    
    dispatch_async(serialQueue_, ^{
        // submit saved sessions
        if ([ServerManager isOnline]) {
            NSMutableArray *sessions = [_userdata sessions];
            NSLog(@"%d saved sessions",[sessions count]);
            while ([sessions count] > 0) {
                SessionData *session = [[SessionData alloc]
                                        initWithJSONObject:[sessions objectAtIndex:0]];
                if (![ServerManager submitSessionData:session]) {
                    NSLog(@"Fail to send, aborting");
                    break;
                } else {
                    [sessions removeObjectAtIndex:0];
                    NSLog(@"Session sent!");
                }
            }
        }
        
        // Fetch new data
        NSDictionary *jsonObj = [ServerManager fetchDataForUsername:[_userdata username]
                                                           password:[_userdata password]];
        
        if (jsonObj != nil) {
            _languages = [jsonObj objectForKey:@"languages"];
            [self saveGlobalData];
            
            NSDictionary *classifiers = [jsonObj objectForKey:@"classifiers"];
            [_userdata setClassifiers:[[NSMutableDictionary alloc]
                                       initWithDictionary:classifiers]];
            // rebuild cache
            [_userdata switchToLanguageId:[_userdata languageId]];
            NSLog(@"Classifiers updated");
            [self saveUserData];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert dismissWithClickedButtonIndex:0 animated:YES];
            });
            
        } else {
            [self saveUserData];
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert dismissWithClickedButtonIndex:0 animated:YES];
                [ServerManager showConnectionError:@"Connect to the internet to synchronize your data."];
            });
        }
    });
}





@end
