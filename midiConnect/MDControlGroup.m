//
//  MDControlGroup.m
//  midiConnect
//
//  Created by Brandon Withrow on 11/6/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "MDControlGroup.h"
#import "MDDial.h"

@implementation MDControlGroup

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{@"groupName" : @"name",
           @"controls" : @"controls",
           @"groupID" : @"groupID",
           @"isAlwaysActive" : @"isAlwaysActive"};
}

+ (NSValueTransformer *)controlsJSONTransformer {
  // tell Mantle to populate diaAttributes property with an array of MDAttribute objects
  return [MTLJSONAdapter arrayTransformerWithModelClass:[MDDial class]];
}

@end
