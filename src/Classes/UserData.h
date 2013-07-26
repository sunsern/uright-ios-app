//
//  UserStorage.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 11/6/12.
//
//

#import <Foundation/Foundation.h>
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
@property (nonatomic,copy) NSString *username;
@property (nonatomic,strong) NSMutableArray *sessions;
@property (nonatomic,strong) NSMutableDictionary *scores;
@property (nonatomic,strong) NSDictionary *protosets;
@property (nonatomic,strong) Charset *customCharset;

+ (Userdata *)emptyUserdata:(int)userID;

- (void)addScore:(float)score;

- (NSArray *)scoreArray;

- (float)bestScore;

- (void)addSessionJSON:(id)sessionJSON;

- (NSArray *)prototypesWithLabels:(NSArray *)labels;

- (NSArray *)protosetIDsWithLabels:(NSArray *)labels;

@end
