//
//  Charset.m
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/13/13.
//
//

#import "Charset.h"

@implementation Charset

- (id)initWithJSONObject:(id)jsonObj {
    self = [super init];
    if (self) {
        _charsetID = [jsonObj[@"charsetID"] intValue];
        _name = [jsonObj[@"name"] copy];
        _characters = [[NSArray alloc] initWithArray:jsonObj[@"characters"]];
    }
    return self;
}

- (id)toJSONObject {
    return @{@"charsetID":@(_charsetID),
             @"name":_name,
             @"characters":_characters};
}

@end
