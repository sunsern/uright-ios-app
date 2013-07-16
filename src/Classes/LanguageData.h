//
//  LanguageData.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/13/13.
//
//

#import <Foundation/Foundation.h>
#import "URJSONSerializable.h"

@interface LanguageInfo : NSObject <URJSONSerializable>
@property (nonatomic,copy) NSString *name;
@property (nonatomic,strong) NSArray *labels;
@property int languageID;
@end


@interface LanguageData : NSObject <URJSONSerializable>

@property (nonatomic,strong) NSMutableDictionary *languages;

- (LanguageInfo *)languageWithID:(int)languageID;

@end
