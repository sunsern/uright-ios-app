//
//  UserStorage.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//
//

#import <Foundation/Foundation.h>

#import "GlobalStorage.h"
#import "URJSONSerializable.h"

@class SessionData;

@interface Protoset : NSObject <URJSONSerializable>
@property (readwrite) int protosetID;
@property (nonatomic,strong) NSString *label;
@property (nonatomic,strong) NSString *type;
@property (nonatomic,strong) NSArray *prototypes;
@end

@interface Userdata : NSObject <URJSONSerializable>

@property (readwrite) int userID;
@property (readwrite) int level;
@property (readwrite) float experience;
@property (readwrite) float thisLevelExp;
@property (readwrite) float nextLevelExp;
@property (readwrite) float bestBps;
@property (nonatomic,copy) NSString *username;
@property (nonatomic,strong) NSArray *scores;
@property (nonatomic,strong) NSMutableArray *sessions;
@property (nonatomic,strong) NSDictionary *protosets;
@property (nonatomic,strong) Charset *customCharset;

+ (Userdata *)emptyUserdata:(int)userID;

- (void)addSessionJSON:(id)sessionJSON;

- (NSArray *)prototypesWithLabels:(NSArray *)labels;

- (NSArray *)protosetIDsWithLabels:(NSArray *)labels;

@end
