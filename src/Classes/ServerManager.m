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
#import "Charset.h"

@implementation ServerManager

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


+ (NSString *)convertToString:(id)jsonObj {
    NSData *data = [[self class] NSDataFromJSONObject:jsonObj];
    NSString *str = [[NSString alloc] initWithData:data
                                          encoding:NSUTF8StringEncoding];
    return str;
}

+ (BOOL)uploadSessionData:(SessionData *)data {
    if ([data.rounds count] > 0 && data.userID != kURGuestUserID) {
        NSString *urlString = [NSString stringWithFormat:@"%@/upload", kURBaseURL];
        NSURL *url = [NSURL URLWithString:urlString];
        ASIFormDataRequest  *request = [ASIFormDataRequest requestWithURL:url];
        
        NSString *activeChars = [[self class] convertToString:data.activeCharacters];
        NSString *activePIDs = [[self class] convertToString:data.activeProtosetIDs];
        NSString *jsonStr = [[self class] convertToString:[data toJSONObject]];
        
        [request setPostValue:kURMagicKey forKey:@"key"];
        [request setPostValue:jsonStr forKey:@"session_json"];
        [request setPostValue:@(data.userID) forKey:@"user_id"];
        [request setPostValue:@(data.modeID) forKey:@"mode_id"];
        [request setPostValue:@(data.bps) forKey:@"bps"];
        [request setPostValue:@(data.totalTime) forKey:@"total_time"];
        [request setPostValue:@(data.totalScore) forKey:@"total_score"];
        [request setPostValue:activeChars forKey:@"active_characters"];
        [request setPostValue:activePIDs forKey:@"active_protoset_ids"];

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


+ (NSArray *)fetchCharsets {
    NSString *urlString = [NSString stringWithFormat:@"%@/charsets", kURBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    ASIFormDataRequest  *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:kURMagicKey forKey:@"key"];
    [request startSynchronous];
    if ([request error] != nil) {
        return nil;
    }
    NSArray *charSetsJSON = [[self class]
                             JSONObjectFromNSData:[request responseData]];
    NSMutableArray *charsets = [[NSMutableArray alloc] init];
    for (id eachCharset in charSetsJSON) {
        [charsets addObject:[[Charset alloc] initWithJSONObject:eachCharset]];
    }
    return charsets;
}


+ (NSDictionary *)fetchProtosets:(int)userID {
    NSString *urlString = [NSString stringWithFormat:@"%@/protosets", kURBaseURL];
    NSURL *url = [NSURL URLWithString:urlString];
    ASIFormDataRequest  *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:kURMagicKey forKey:@"key"];
    [request setPostValue:@(userID) forKey:@"user_id"];
    [request startSynchronous];
    if ([request error] != nil) {
        return nil;
    }
    NSDictionary *protosetsJSON = [[self class]
                                   JSONObjectFromNSData:[request responseData]];
    
    NSMutableDictionary *protosets = [[NSMutableDictionary alloc] init];
    for (id key in protosetsJSON) {
        Protoset *ps = [[Protoset alloc] initWithJSONObject:protosetsJSON[key]];
        protosets[ps.label] = ps;
    }
    return protosets;
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
