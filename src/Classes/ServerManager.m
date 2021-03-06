//
//  ServerManager.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 6/1/12.
//

#import <CommonCrypto/CommonDigest.h>

#import "ServerManager.h"

#import "ASIFormDataRequest.h"
#import "Charset.h"
#import "GlobalStorage.h"
#import "Reachability.h"
#import "SessionData.h"
#import "Userdata.h"

NSString* hashedPassword(NSString *password) {
    const char *cStr = [password UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, strlen(cStr), digest ); // This is the md5 call
    
    NSMutableString *hashed = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [hashed appendFormat:@"%02x", digest[i]];
    return hashed;
}

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
    
    NSString *hashed = hashedPassword(password);
    NSString *urlString = [NSString stringWithFormat:@"%@/newuser", UR_BASE_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:username forKey:@"username"];
    [request setPostValue:hashed forKey:@"password"];
    [request setPostValue:email forKey:@"email"];
    [request setPostValue:fullname forKey:@"fullname"];
    [request setPostValue:UR_MAGIC_KEY forKey:@"key"];
    [request startSynchronous];
    if ([request error] != nil) {
        return UR_GUEST_ID;
    }
    NSDictionary *response = [[self class] JSONObjectFromNSData:[request responseData]];
    if (response) {
        return [response[@"user_id"] intValue];
    } else {
        return UR_GUEST_ID;
    }
}

+ (int)loginWithUsername:(NSString *)username
                password:(NSString *)password  {
    
    NSString *hashed = hashedPassword(password);
    NSString *urlString = [NSString stringWithFormat:@"%@/login", UR_BASE_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:username forKey:@"username"];
    [request setPostValue:hashed forKey:@"password"];
    [request setPostValue:UR_MAGIC_KEY forKey:@"key"];
    [request startSynchronous];
    if ([request error] != nil) {
        return UR_GUEST_ID;
    }
    NSDictionary *response = [[self class] JSONObjectFromNSData:[request responseData]];
    if (response && [response[@"login_result"] isEqualToString:@"OK"]) {
        return [response[@"user_id"] intValue];
    } else {
        return UR_GUEST_ID;
    }
}

+ (BOOL)uploadSessionData:(SessionData *)data {
    if ([data.rounds count] > 0 && data.userID != UR_GUEST_ID) {
        NSString *urlString = [NSString stringWithFormat:@"%@/upload", UR_BASE_URL];
        NSURL *url = [NSURL URLWithString:urlString];
        ASIFormDataRequest  *request = [ASIFormDataRequest requestWithURL:url];
        
        NSString *activeChars = [[self class] convertToString:data.activeCharacters];
        NSString *activePIDs = [[self class] convertToString:data.activeProtosetIDs];
        NSString *jsonStr = [[self class] convertToString:[data toJSONObject]];
        
        [request setPostValue:UR_MAGIC_KEY forKey:@"key"];
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
    NSString *urlString = [NSString stringWithFormat:@"%@/charsets", UR_BASE_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    ASIFormDataRequest  *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:UR_MAGIC_KEY forKey:@"key"];
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


+ (NSDictionary *)fetchUserStats:(int)userID {
    NSString *urlString = [NSString stringWithFormat:@"%@/userstats", UR_BASE_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    ASIFormDataRequest  *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:UR_MAGIC_KEY forKey:@"key"];
    [request setPostValue:@(userID) forKey:@"user_id"];
    [request startSynchronous];
    if ([request error] != nil) {
        return nil;
    }
    NSDictionary *result = [[self class]
                            JSONObjectFromNSData:[request responseData]];
    if ([result[@"Error"] intValue] > 0) {
        return nil;
    }
    return result;
}


+ (NSDictionary *)fetchProtosets:(int)userID {
    NSString *urlString = [NSString stringWithFormat:@"%@/protosets", UR_BASE_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    ASIFormDataRequest  *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:UR_MAGIC_KEY forKey:@"key"];
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

+ (NSDictionary *)announcement {
    NSString *urlString = [NSString stringWithFormat:@"%@/annoucement", UR_BASE_URL];
    NSURL *url = [NSURL URLWithString:urlString];
    ASIFormDataRequest  *request = [ASIFormDataRequest requestWithURL:url];
    [request setPostValue:UR_MAGIC_KEY forKey:@"key"];
    [request startSynchronous];
    if ([request error] != nil) {
        return nil;
    }
    return [[self class] JSONObjectFromNSData:[request responseData]];
}


#pragma mark Helper mthods

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

+ (NSString *)convertToString:(id)jsonObj {
    NSData *data = [[self class] NSDataFromJSONObject:jsonObj];
    NSString *str = [[NSString alloc] initWithData:data
                                          encoding:NSUTF8StringEncoding];
    return str;
}


@end
