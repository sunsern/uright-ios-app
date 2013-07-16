//
//  BFPrototype.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/12/13.
//
//

#import <Foundation/Foundation.h>
#import "URJSONSerializable.h"

@interface BFPrototype : NSObject <URJSONSerializable>

@property (nonatomic,copy) NSString *label;
@property (nonatomic,strong) NSArray *points;
@property (readwrite) float prior;

- (int)length;

@end
