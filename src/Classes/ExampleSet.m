//
//  ExampleSet.m
//  Handwriting
//
//  Created by Sunsern Cheamanunkul on 4/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ExampleSet.h"

#import "InkExample.h"

@implementation ExampleSet

@synthesize examples = _examples;

- (id)init {
    self = [super init];
    if (self) {
        _classifier_id = 0;
        _language_id = 0;
        _created_on = @"";
        _examples = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initWithJSONObject:(NSDictionary *)jsonObject {
    self = [self init];
    if (self && jsonObject != nil) {
        _classifier_id = [[jsonObject objectForKey:@"classifier_id"] intValue];
        _language_id = [[jsonObject objectForKey:@"language_id"] intValue];
        _created_on = [[jsonObject objectForKey:@"created_on"] copy];
        NSArray *examples = [jsonObject objectForKey:@"classifier_json"];
        for (NSDictionary *example in examples) {
            [self addExample:[[InkExample alloc] initWithJSONObject:example]];
        }
    }
    return self;
}

- (NSArray *)toJSONObject {
    NSMutableArray *allExamples = [[NSMutableArray alloc] init];
    NSArray *keys = [_examples allKeys];
    for (NSString *key in keys) {
        NSArray *examples = [_examples objectForKey:key];
        for (InkExample *example in examples) {
            [allExamples addObject:[example toJSONObject]];
        }
    }
    return allExamples;
}

- (void)addExample:(InkExample *)example {
    NSString *label = [example label];
    NSMutableArray *exampleArray = [_examples objectForKey:label];
	if (exampleArray == nil) {
		exampleArray = [NSMutableArray arrayWithObject:example];
	} else {
     	[exampleArray addObject:example];
	}
    //NSLog(@"adding an example for %@",label);
	[_examples setObject:exampleArray forKey:label];
}

- (void)addExamplesFromDataset:(ExampleSet *)anotherDataset {
    NSArray *allLabels = [anotherDataset labels];
    for (NSString *eachLabel in allLabels) {
        NSArray *exampleArray = [[anotherDataset examples] objectForKey:eachLabel];
        for (InkExample *eachExample in exampleArray) {
            [self addExample:eachExample];
        }
    }
}

- (void)addLabel:(NSString *)label {
    // check if label exists
	NSSet *labelSet = [NSSet setWithArray:[_examples allKeys]];
	if (![labelSet containsObject:label]) {
		// Insert empty array to be a place holder
		[_examples setObject:[NSMutableArray array] forKey:label];
	}
}

- (void)removeExampleAtIndex:(int)exampleIdx label:(NSString *)label {
    NSMutableArray *exampleArray = [_examples objectForKey:label];
	if (exampleArray != nil && exampleIdx < [exampleArray count]) {
		[exampleArray removeObjectAtIndex:exampleIdx];
	}
	[_examples setObject:exampleArray forKey:label];
}

- (void)removeAllExamples {
    [_examples removeAllObjects];
}

- (NSArray *)labels {
    NSSet *labelSet = [NSSet setWithArray:[_examples allKeys]];
	NSArray *unsortedLabels = [labelSet allObjects];
	return [unsortedLabels sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
}

- (int)labelCount {
    NSSet *labelSet = [NSSet setWithArray:[_examples allKeys]];
    return [labelSet count];
}

- (int)exampleCount:(NSString *)label {
    NSArray *exampleArray = [_examples objectForKey:label];
	if (exampleArray) {
		return [exampleArray count];
	} else {
        return 0;
    }
}

- (int)exampleCount {
    int count = 0;
    for (NSString *key in [_examples allKeys]) {
        count += [self exampleCount:key];
    }
    return count;
}

@end
