//
//  ServerManager.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 6/1/12.
//

#import "ServerManager.h"

#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"
#import "SessionData.h"
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
    
    NSString *urlString = [NSString stringWithFormat:@"%@/login", kURBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    
    [request setPostValue:username forKey:@"username"];
    [request setPostValue:password forKey:@"password"];
    [request setPostValue:kURMagicKey forKey:@"key"];
    
    [request startSynchronous];
    if ([request error] != nil) {
        return nil;
    }
    
    NSError *error;
    NSLog(@"%@",[request responseString]);
    return [NSJSONSerialization JSONObjectWithData:[request responseData]
                                           options:kNilOptions
                                             error:&error];
}


+ (int)createAccountForUsername:(NSString *)username
                        password:(NSString *)password
                           email:(NSString *)email
                        fullname:(NSString *)fullname {
    
    const char *cStr = [password UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *hashed = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [hashed appendFormat:@"%02x", digest[i]];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/newuser", kURBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:username forKey:@"username"];
    [request setPostValue:hashed forKey:@"password"];
    [request setPostValue:email forKey:@"email"];
    [request setPostValue:fullname forKey:@"fullname"];
    [request setPostValue:kURMagicKey forKey:@"key"];
    
    NSLog(@"email=%@",email);

    [request startSynchronous];
    if ([request error] != nil) {
        return -1;
    }
    
    NSError *error;
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:[request responseData]
                                                             options:kNilOptions
                                                               error:&error];
    return [response[@"user_id"] intValue];
}



+ (NSDictionary *)getUserIdFromUsername:(NSString *)username
                               password:(NSString *)password  {

    const char *cStr = [password UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *hashed = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [hashed appendFormat:@"%02x", digest[i]];
    
    NSString *urlString = [NSString stringWithFormat:@"%@/login", kURBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:username forKey:@"username"];
    [request setPostValue:password forKey:@"password"];
    [request setPostValue:kURMagicKey forKey:@"key"];

    [request startSynchronous];
    if ([request error] != nil) {
        return nil;
    }
    
    NSError *error;
    NSDictionary *response = [NSJSONSerialization JSONObjectWithData:[request responseData]
                                                             options:kNilOptions
                                                               error:&error];
    return response;
}

+ (NSData *)json2data:(id)jsonObj {
    NSError *error;
    return [NSJSONSerialization dataWithJSONObject:jsonObj
                                           options:kNilOptions
                                             error:&error];
}

+ (NSDictionary *)submitSessionData:(SessionData *)data {
    if ([data.rounds count] > 0) {
        NSString *urlString = [NSString stringWithFormat:@"%@cgi/submit_session.php?key=iosexp2", kURBaseURL];
        NSURL *url = [NSURL URLWithString:urlString];
        ASIFormDataRequest  *request = [ASIFormDataRequest requestWithURL:url];
        
        NSData *jsondata = [[self class] json2data:[data toJSONObject]];
        NSString *jsonString = [[NSString alloc] initWithData:jsondata
                                                     encoding:NSUTF8StringEncoding];
        
        [request setPostValue:jsonString forKey:@"collected_data_json"];
        [request setPostValue:[NSString stringWithFormat:@"%d", data.userID]
                       forKey:@"user_id"];
        [request setPostValue:[NSString stringWithFormat:@"%d", data.modeID]
                       forKey:@"mode_id"];
        [request setPostValue:[NSString stringWithFormat:@"%d", data.classifierID]
                       forKey:@"classifier_id"];
        [request setPostValue:[NSString stringWithFormat:@"%d", data.languageID]
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



+ (void)synchronizeData {
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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        GlobalStorage *gs = [GlobalStorage sharedInstance];
        UserData *us = [gs activeUser];
        
        // submit saved sessions
        if ([[self class] isOnline]) {
            NSMutableArray *sessions = [us sessions];
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
        NSDictionary *jsonObj = [[self class] fetchDataForUsername:[us username]
                                                          password:[us password]];
        
        if (jsonObj != nil) {
            [gs setLanguages:[[LanguageData alloc] initWithJSONObject:jsonObj[@"languages"]]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert dismissWithClickedButtonIndex:0 animated:YES];
            });
            
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [alert dismissWithClickedButtonIndex:0 animated:YES];
                [ServerManager showConnectionError:@"Connect to the internet to synchronize your data."];
            });
        }
    });
}





@end
