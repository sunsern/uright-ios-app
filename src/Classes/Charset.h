//
//  Charset.h
//  uRight3
//
//  Created by Sunsern Cheamanunkul on 7/13/13.
//
//

#import <Foundation/Foundation.h>
#import "URJSONSerializable.h"

@interface Charset : NSObject <URJSONSerializable>

@property (nonatomic,copy) NSString *name;
@property (nonatomic,strong) NSArray *characters;
@property int charsetID;

@end
