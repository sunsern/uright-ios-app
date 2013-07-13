//
//  InkExample.m
//  Handwriting
//
//  Created by Sunsern Cheamanunkul on 4/6/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "InkExample.h"

#import "InkCharacter.h"

@implementation InkExample 

- (id)initWithInkCharacter:(InkCharacter *)ink label:(NSString *)label {
    self = [super init];
    if (self) {
        _inkCharacter = [[InkCharacter alloc]
                         initWithJSONObject:[ink toJSONObject]];
        _label = [label copy];
    }
    return self; 
}

- (id)initWithJSONObject:(NSDictionary *)jsonObj {
    self = [super init];
    if (self) {
        _inkCharacter = [[InkCharacter alloc]
                         initWithJSONObject:jsonObj[@"character"]];
        _label = [jsonObj[@"label"] copy];
    }
    return self;
}

- (NSDictionary *)toJSONObject {
    NSMutableDictionary *jsonObj = [[NSMutableDictionary alloc] init];
    jsonObj[@"character"] = [_inkCharacter toJSONObject];
    jsonObj[@"label"] = _label;
    return jsonObj;
}

@end
