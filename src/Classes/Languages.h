//
//  LanguageDefinition.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/13/13.
//
//

#import <Foundation/Foundation.h>

@interface LanguageInfo : NSObject

@property (nonatomic,copy) NSString *languageName;
@property (nonatomic,strong) NSArray *allLabels;
@property int languageId;

- (id)initWithJSONObject:(id)jsonObj;
- (id)toJSONObject;

@end


@interface Languages : NSObject

@property (nonatomic,strong) NSMutableDictionary *languages;

- (id)initWithJSONObject:(id)jsonObj;
- (id)toJSONObject;

- (LanguageInfo *)languageWithId:(int)languageId;

@end
