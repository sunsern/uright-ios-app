//
//  UserStorage.m
//  uRight2
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//
//

#import "UserData.h"

#import "BFPrototype.h"
#import "SessionData.h"
#import "Charset.h"

#define kMaxScoreHistory 10
#define kDefaultScoreKey @"default"

@implementation Protoset

- (id)initWithJSONObject:(id)jsonObj {
    self = [super init];
    if (self) {
        _protosetID = [jsonObj[@"protosetID"] intValue];
        _label = [jsonObj[@"label"] copy];
        _type = [jsonObj[@"type"] copy];
        NSMutableArray *prototypes = [[NSMutableArray alloc] init];
        for (id each_proto in jsonObj[@"prototypes"]) {
            [prototypes addObject:[[BFPrototype alloc] initWithJSONObject:each_proto]];
        }
        _prototypes = (NSArray *)prototypes;
    }
    return self;
}

- (id)toJSONObject {
    NSMutableDictionary *jsonObj = [[NSMutableDictionary alloc] init];
    jsonObj[@"protosetID"] = @(_protosetID);
    jsonObj[@"label"] = _label;
    jsonObj[@"type"] = _type;
    NSMutableArray *prototypes = [[NSMutableArray alloc] init];
    for (BFPrototype *prot in _prototypes) {
        [prototypes addObject:[prot toJSONObject]];
    }
    jsonObj[@"prototypes"] = (NSArray *)prototypes;
    return jsonObj;
}

@end

@implementation Userdata

- (id)init {
    self = [super init];
    if (self) {
        _userID = UR_GUEST_ID;
        _username = @"";
        _sessions = [[NSMutableArray alloc] init];
        _scores = [[NSMutableDictionary alloc] init];
        _protosets = [[NSDictionary alloc] init];
        _customCharset = [Charset emptyCharset];
    }
    return self;
}

- (id)initWithJSONObject:(NSDictionary *)jsonObj {
    self = [super init];
    if (self) {
        _userID = [jsonObj[@"userID"] intValue];
        _username = [jsonObj[@"username"] copy];
        _sessions = [[NSMutableArray alloc]
                     initWithArray:jsonObj[@"sessions"]];
        _scores = [[NSMutableDictionary alloc]
                   initWithDictionary:jsonObj[@"scores"]];
        NSMutableDictionary *protosets = [[NSMutableDictionary alloc] init];
        for (id key in jsonObj[@"protosets"]) {
            protosets[key] = [[Protoset alloc] initWithJSONObject:jsonObj[@"protosets"][key]];
        }
        _protosets = (NSDictionary *)protosets;
        _customCharset = [[Charset alloc] initWithJSONObject:jsonObj[@"customCharset"]];
    }
    return self;
}


- (NSDictionary *)toJSONObject {
    NSMutableDictionary *jsonObj = [[NSMutableDictionary alloc] init];
    jsonObj[@"userID"] = @(_userID);
    jsonObj[@"username"] = _username;
    jsonObj[@"sessions"] = _sessions;
    jsonObj[@"scores"] = _scores;
    NSMutableDictionary *protosets = [[NSMutableDictionary alloc] init];
    for (id key in _protosets) {
        protosets[key] = [_protosets[key] toJSONObject];
    }
    jsonObj[@"protosets"] = protosets;
    jsonObj[@"customCharset"] = [_customCharset toJSONObject];
    return jsonObj;
}


+ (Userdata *)emptyUserdata:(int)userID {
    Userdata *ud = [[Userdata alloc] init];
    ud.userID = userID;
    
    if (userID == UR_GUEST_ID) {
        ud.username = @"Guest";
    } else {
        ud.username = @"unknown";
    }
    return ud;
}


- (void)addScore:(float)score {
    NSDictionary *scoreStruct = _scores[kDefaultScoreKey];
    if (scoreStruct != nil) {
        float max_score = [scoreStruct[@"maxscore"] floatValue];
        float avg_score = [scoreStruct[@"avgscore"] floatValue];
        int num_sessions = [scoreStruct[@"numsessions"] intValue];
        NSMutableArray *scoreArray = [[NSMutableArray alloc] initWithArray:
                                      scoreStruct[@"scores"]];
        if (score > max_score) {
            max_score = score;
        }
        avg_score = (avg_score * num_sessions + score) / (num_sessions + 1);
        num_sessions++;
        while ([scoreArray count] >= kMaxScoreHistory) {
            [scoreArray removeObjectAtIndex:0];
        }
        [scoreArray addObject:[NSNumber numberWithFloat:score]];
        NSDictionary *newScoreStruct = @{@"maxscore":@(max_score),
                                         @"avgscore":@(avg_score),
                                         @"numsessions":@(num_sessions),
                                         @"scores":scoreArray};
        _scores[kDefaultScoreKey] = newScoreStruct;
    } else {
        NSDictionary *newScoreStruct = @{@"maxscore":@(score),
                                         @"avgscore":@(score),
                                         @"numsessions":@(1),
                                         @"scores":@[@(score)]};
        _scores[kDefaultScoreKey] = newScoreStruct;
    }
}

- (NSArray *)scoreArray {
    return _scores[kDefaultScoreKey][@"scores"];
}

- (float)bestScore {
    NSDictionary *scoreStruct = _scores[kDefaultScoreKey];
    if (scoreStruct == nil) {
        return 0.0;
    } else {
        return [scoreStruct[@"maxscore"] floatValue];
    }
}

- (void)addSessionJSON:(id)sessionJSON {
    [_sessions addObject:sessionJSON];
}


- (NSArray *)prototypesWithLabels:(NSArray *)labels {
    NSMutableArray *activeProtList = [[NSMutableArray alloc] init];
    for (id key in labels) {
        Protoset *ps = _protosets[key];
        for (BFPrototype *prot in ps.prototypes) {
            [activeProtList addObject:prot];
        }
    }
    return (NSArray *)activeProtList;
}


- (NSArray *)protosetIDsWithLabels:(NSArray *)labels {
    NSMutableArray *activeProtosetIDs = [[NSMutableArray alloc] init];
    for (id key in labels) {
        Protoset *ps = _protosets[key];
        if (ps) {
            [activeProtosetIDs addObject:@(ps.protosetID)];
        }
    }
    return (NSArray *)activeProtosetIDs;
}
@end
