//
//  ServerManager.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 6/1/12.
//

#import <CommonCrypto/CommonDigest.h>

#import "ServerManager.h"
#import "ASIFormDataRequest.h"
#import "Reachability.h"
#import "SessionData.h"

static UIAlertView *__busy = nil;

@implementation ServerManager

+ (void)showConnectionError:(NSString *)message {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Error"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}

+ (void)showBusyAlert:(NSString *)message {
    __busy = [[UIAlertView alloc] initWithTitle:@"Please wait"
                                        message:message
                                       delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:nil];
    if(__busy != nil) {
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        indicator.center = CGPointMake(__busy.bounds.size.width/2, __busy.bounds.size.height-45);
        [indicator startAnimating];
        [__busy addSubview:indicator];
    }
    [__busy show];
}


+ (void)closeBusyAlert {
    if (__busy) {
        [__busy dismissWithClickedButtonIndex:0 animated:YES];
        __busy = nil;
    }
}

+ (BOOL)isOnline {
    NetworkStatus internetStatus = [[Reachability reachabilityForInternetConnection]
                                    currentReachabilityStatus];
    return (internetStatus != NotReachable);
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
    [request startSynchronous];
    if ([request error] != nil) {
        return kURGuestUserID;
    }
    NSDictionary *response = [[self class] JSONObjectFromNSData:[request responseData]];
    if (response) {
        return [response[@"user_id"] intValue];
    } else {
        return kURGuestUserID;
    }
}

+ (int)getUserIDFromUsername:(NSString *)username
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
    [request setPostValue:hashed forKey:@"password"];
    [request setPostValue:kURMagicKey forKey:@"key"];
    [request startSynchronous];
    if ([request error] != nil) {
        return kURGuestUserID;
    }
    NSDictionary *response = [[self class] JSONObjectFromNSData:[request responseData]];
    if (response && [response[@"login_result"] isEqualToString:@"OK"]) {
        return [response[@"user_id"] intValue];
    } else {
        return kURGuestUserID;
    }
}


+ (BOOL)uploadSessionData:(SessionData *)data {
    if ([data.rounds count] > 0 && data.userID != kURGuestUserID) {
        NSString *urlString = [NSString stringWithFormat:@"%@/upload", kURBaseURL];
        NSURL *url = [NSURL URLWithString:urlString];
        ASIFormDataRequest  *request = [ASIFormDataRequest requestWithURL:url];
        NSData *jsondata = [[self class] NSDataFromJSONObject:[data toJSONObject]];
        NSString *jsonStr = [[NSString alloc] initWithData:jsondata
                                                     encoding:NSUTF8StringEncoding];
        [request setPostValue:kURMagicKey forKey:@"key"];
        [request setPostValue:jsonStr forKey:@"raw_json"];
        [request setPostValue:@(data.userID) forKey:@"user_id"];
        [request setPostValue:@(data.modeID) forKey:@"mode_id"];
        [request setPostValue:@(data.classifierID) forKey:@"classifier_id"];
        [request setPostValue:@(data.languageID) forKey:@"language_id"];
        [request setPostValue:@(data.bps) forKey:@"bps"];
        [request setPostValue:@(data.totalTime) forKey:@"total_time"];
        [request setPostValue:@(data.totalScore) forKey:@"total_score"];
        [request startSynchronous];
        if ([request error] != nil) {
            return NO;
        }
        NSDictionary *result = [[self class] JSONObjectFromNSData:[request responseData]];
        if ([result[@"Error"] intValue] > 0) {
            return NO;
        }
    }
    return YES;
}


+ (NSDictionary *)fetchLanguageData {
    NSString *urlString = [NSString stringWithFormat:@"%@/languages", kURBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    ASIFormDataRequest  *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:kURMagicKey forKey:@"key"];
    [request startSynchronous];
    if ([request error] != nil) {
        return nil;
    }
    return [[self class] JSONObjectFromNSData:[request responseData]];
}


+ (NSDictionary *)fetchClassifiers {
    NSString *urlString = [NSString stringWithFormat:@"%@/classifiers", kURBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    ASIFormDataRequest  *request = [ASIFormDataRequest requestWithURL:url];
    int userID = [[GlobalStorage sharedInstance] activeUserID];
    [request setPostValue:kURMagicKey forKey:@"key"];
    [request setPostValue:@(userID) forKey:@"user_id"];
    [request startSynchronous];
    if ([request error] != nil) {
        return nil;
    }
    return [[self class] JSONObjectFromNSData:[request responseData]];    
}


// Helper methods
+ (id)JSONObjectFromNSData:(NSData *)data {
    NSError *error;
    return [NSJSONSerialization JSONObjectWithData:data
                                           options:kNilOptions
                                             error:&error];
}


+ (NSData *)NSDataFromJSONObject:(id)jsonObj {
    NSError *error;
    return [NSJSONSerialization dataWithJSONObject:jsonObj
                                           options:kNilOptions
                                             error:&error];
}

@end
