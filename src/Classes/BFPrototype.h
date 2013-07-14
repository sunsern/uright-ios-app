//
//  BFPrototype.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/12/13.
//
//

#import <Foundation/Foundation.h>

@interface BFPrototype : NSObject

@property (nonatomic,copy) NSString *label;
@property (nonatomic,strong) NSArray *pointArray;
@property (readwrite) float prior;

- (id)initWithJSONObject:(id)jsonObj;
- (int)length;

@end
