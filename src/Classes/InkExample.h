//
//  InkExample.h
//  uRight
//
//  Created by Sunsern Cheamanunkul on 4/6/12.
//

#import <Foundation/Foundation.h>

@class InkCharacter;

@interface InkExample : NSObject

@property (nonatomic, strong) InkCharacter *inkCharacter;
@property (nonatomic, copy) NSString *label;

- (id)initWithInkCharacter:(InkCharacter *)ink label:(NSString *)label;

// Serialization
- (id)initWithJSONObject:(NSDictionary *)jsonObj;
- (NSDictionary *)toJSONObject;

@end
