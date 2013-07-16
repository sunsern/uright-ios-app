//
//  ClassificationResult.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 4/13/12.
//

#import <Foundation/Foundation.h>
#import "URJSONSerializable.h"

@interface ClassificationResult : NSObject <URJSONSerializable>

@property (nonatomic,strong) NSDictionary *scores;

- (id)initWithDictionary:(NSDictionary *)dict;

// best answer is rank 0
- (NSString *)predictionByRanking:(int)rank;

- (double)scoreByRanking:(int)rank;

- (double)scoreByLabel:(NSString *)label;

@end
