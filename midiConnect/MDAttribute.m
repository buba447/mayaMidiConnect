//
//  MDAttribute.m
//  midiConnect
//
//  Created by Brandon Withrow on 11/6/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "MDAttribute.h"

@implementation MDAttribute

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{@"inMinValue" : @"inMinValue",
           @"inMaxValue" : @"inMaxValue",
           @"outMinValue" : @"outMinValue",
           @"outMaxValue" : @"outMaxValue",
           @"mayaNode" : @"mayaNode",
           @"mayaAttribute" : @"mayaAttribute",
           @"mayaCommand" : @"mayaCommand",
           @"attributeID" : @"attributeID"
           };
}

@end
