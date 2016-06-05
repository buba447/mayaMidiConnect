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
  return @{@"inRange" : @"inRange",
           @"outRange" : @"outRange",
           @"mayaNode" : @"mayaNode",
           @"mayaAttribute" : @"mayaAttribute",
           @"mayaCommand" : @"mayaCommand",
           @"attributeID" : @"attributeID"
           };
}

- (void)setOutputValue:(NSNumber *)outputValue forInputValue:(NSNumber *)inputValue {
  if (!self.inRange) {
    self.inRange = @[inputValue];
    self.outRange = @[outputValue];
    return;
  }
  
  NSMutableDictionary *dictionary =
    [NSMutableDictionary dictionaryWithObjects:self.outRange forKeys:self.inRange];
  [dictionary setObject:outputValue forKey:inputValue];
  
  NSMutableArray *inputRange = [NSMutableArray arrayWithArray:dictionary.allKeys];
  [inputRange sortUsingSelector:@selector(compare:)];
  
  NSMutableArray *outputRange = [NSMutableArray new];
  for (NSNumber *number in inputRange) {
    [outputRange addObject:[dictionary objectForKey:number]];
  }
  self.inRange = inputRange;
  self.outRange = outputRange;
}

- (void)removeValueForInput:(NSNumber *)inputValue {
  NSInteger idx = [self.inRange indexOfObject:inputValue];
  if (idx >= 0) {
    NSMutableArray *inputRange = [NSMutableArray arrayWithArray:self.inRange];
    NSMutableArray *outputRange = [NSMutableArray arrayWithArray:self.outRange];
    [inputRange removeObjectAtIndex:idx];
    [outputRange removeObjectAtIndex:idx];
    self.inRange = inputRange;
    self.outRange = outputRange;
  }
}

@end
