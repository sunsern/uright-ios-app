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
        _inkCharacter = ink;
        _label = [label copy];
    }
    return self; 
}

- (id)initWithJSONObject:(NSDictionary *)jsonObj {
    self = [super init];
    if (self) {
        _inkCharacter = [[InkCharacter alloc]
                         initWithJSONObject:[jsonObj objectForKey:@"character"]];
        _label = [[jsonObj objectForKey:@"label"] copy];
    }
    return self;
}

- (NSDictionary *)toJSONObject {
    NSMutableDictionary *jsonObj = [[NSMutableDictionary alloc] initWithCapacity:2];
    [jsonObj setObject:[_inkCharacter toJSONObject] forKey:@"character"];
    [jsonObj setObject:_label forKey:@"label"];
    return jsonObj;
}

@end
