//
//  ExampleSet.h
//  Handwriting
//
//  Created by Sunsern Cheamanunkul on 4/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class InkExample;

@interface ExampleSet : NSObject {
    NSMutableDictionary *_examples;
}

@property (nonatomic,strong,readonly) NSDictionary *examples;
@property (nonatomic,copy) NSString *created_on;
@property int classifier_id;
@property int language_id;

- (id)initWithJSONObject:(NSDictionary *)jsonObject;

// Add a new example
- (void)addExample:(InkExample *)example;

// Combine two dataset
- (void)addExamplesFromDataset:(ExampleSet *)anotherDataset;

// Add a new label
- (void)addLabel:(NSString *)label;

// Remove example of a given label at the given index.
- (void)removeExampleAtIndex:(int)exampleIdx label:(NSString *)label;

// Remove all examples;
- (void)removeAllExamples;

// get alphabetically sorted labels
- (NSArray *)labels;
- (int)labelCount;

// get a count of examples of a given label
- (int)exampleCount:(NSString *)label;

- (int)exampleCount;

- (NSDictionary *)toJSONObject;

@end
