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
@property (nonatomic, copy) NSNumber *inMinValue;
@property (nonatomic, copy) NSNumber *inMaxValue;
@property (nonatomic, copy) NSNumber *outMinValue;
@property (nonatomic, copy) NSNumber *outMaxValue;
@property (nonatomic, copy) NSString *mayaNode;
@property (nonatomic, copy) NSString *mayaAttribute;
@property (nonatomic, copy) NSString *mayaCommand;

@end
