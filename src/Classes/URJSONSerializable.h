//
//  URJSONSerializable.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/15/13.
//
//

#import <Foundation/Foundation.h>

@protocol URJSONSerializable <NSObject>

- (id)initWithJSONObject:(id)jsonObj;
- (id)toJSONObject;

@end
