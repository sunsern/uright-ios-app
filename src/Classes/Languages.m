//
//  LanguageDefinition.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/13/13.
//
//

#import "Languages.h"

@implementation LanguageInfo

- (id)initWithJSONObject:(id)jsonObj {
    self = [super init];
    if (self) {
        _languageId = [jsonObj[@"id"] intValue];
        _languageName = [jsonObj[@"name"] copy];
        _allLabels = [[NSArray alloc] initWithArray:jsonObj[@"characters"]];
    }
    return self;
}

- (id)toJSONObject {
    return @{@"id":@(_languageId),
             @"name":_languageName,
             @"characters":_allLabels};
}

@end

@implementation Languages

- (id)initWithJSONObject:(id)jsonObj {
    self = [super init];
    if (self) {
        _languages = [[NSMutableDictionary alloc] init];
        for (id key in jsonObj) {
            _languages[key] = [[LanguageInfo alloc]
                               initWithJSONObject:jsonObj[key]];
        }
    }
    return self;
}

- (id)toJSONObject {
    NSMutableDictionary *jsonObj = [[NSMutableDictionary alloc] init];
    for (id key in _languages) {
        jsonObj[key] = [_languages[key] toJSONObject];
    }
    return jsonObj;
}

- (LanguageInfo *)languageWithId:(int)languageId {
    return _languages[[@(languageId) stringValue]];
}

@end
