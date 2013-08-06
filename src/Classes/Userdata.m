//
//  UserStorage.m
//  uRight2
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//
//

#import "Userdata.h"

#import "BFPrototype.h"
#import "Charset.h"
#import "SessionData.h"

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
        _level = 0;
        _experience = 0.0;
        _thisLevelExp = 0.0;
        _nextLevelExp = 0.0;
        _bestBps = 0.0;
        _scores = [[NSArray alloc] init];
        _username = @"unknown";
        _sessions = [[NSMutableArray alloc] init];
        _protosets = [[NSDictionary alloc] init];
        _customCharset = [Charset emptyCharset];
    }
    return self;
}

- (id)initWithJSONObject:(NSDictionary *)jsonObj {
    self = [super init];
    if (self) {
        _userID = [jsonObj[@"userID"] intValue];
        _level = [jsonObj[@"level"] intValue];
        _experience = [jsonObj[@"experience"] floatValue];
        _thisLevelExp = [jsonObj[@"thisLevelExp"] floatValue];
        _nextLevelExp = [jsonObj[@"nextLevelExp"] floatValue];
        _bestBps = [jsonObj[@"bestBps"] floatValue];
        _username = [jsonObj[@"username"] copy];
        if (jsonObj[@"scores"]) {
            _scores = [[NSArray alloc] initWithArray:jsonObj[@"scores"]];
        }
        _sessions = [[NSMutableArray alloc]
                     initWithArray:jsonObj[@"sessions"]];
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
    jsonObj[@"level"] = @(_level);
    jsonObj[@"experience"] = @(_experience);
    jsonObj[@"thisLevelExp"] = @(_thisLevelExp);
    jsonObj[@"nextLevelExp"] = @(_nextLevelExp);
    jsonObj[@"bextBps"] = @(_bestBps);
    jsonObj[@"scores"] = _scores;
    jsonObj[@"username"] = _username;
    jsonObj[@"sessions"] = _sessions;
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
    return ud;
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
