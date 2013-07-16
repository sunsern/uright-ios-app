//
//  LanguageData.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/13/13.
//
//

#import "LanguageData.h"

@implementation LanguageInfo

- (id)initWithJSONObject:(id)jsonObj {
    self = [super init];
    if (self) {
        _languageID = [jsonObj[@"id"] intValue];
        _name = [jsonObj[@"name"] copy];
        _labels = [[NSArray alloc] initWithArray:jsonObj[@"characters"]];
    }
    return self;
}

- (id)toJSONObject {
    return @{@"id":@(_languageID),
             @"name":_name,
             @"characters":_labels};
}

@end


@implementation LanguageData

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

- (LanguageInfo *)languageWithID:(int)languageID {
    return _languages[[@(languageID) stringValue]];
}

@end
