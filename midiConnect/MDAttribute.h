//
//  MDAttribute.h
//  midiConnect
//
//  Created by Brandon Withrow on 11/6/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "MTLModel.h"

@interface MDAttribute : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy) NSString *attributeID;
@property (nonatomic, copy) NSArray *inRange;
@property (nonatomic, copy) NSArray *outRange;
@property (nonatomic, copy) NSString *mayaNode;
@property (nonatomic, copy) NSString *mayaAttribute;
@property (nonatomic, copy) NSString *mayaCommand;

- (void)setOutputValue:(NSNumber *)outputValue forInputValue:(NSNumber *)inputValue;
- (void)removeValueForInput:(NSNumber *)inputValue;

@end
