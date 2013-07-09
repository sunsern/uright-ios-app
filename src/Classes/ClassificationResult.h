//
//  ClassificationResult.h
//  Handwriting
//
//  Created by Sunsern Cheamanunkul on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ClassificationResult : NSObject

@property (nonatomic,strong,readonly) NSDictionary *resultDictionary;
           
- (id)initWithDictionary:(NSDictionary *)dict;

// best answer is rank 0
- (NSString *)predictionByRanking:(int)rank;

- (double)scoreByRanking:(int)rank;

- (double)scoreByLabel:(NSString *)label;

// Serialization
- (NSDictionary *)toJSONObject;

@end
