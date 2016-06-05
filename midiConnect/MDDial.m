//
//  MDDial.m
//  midiConnect
//
//  Created by Brandon Withrow on 11/6/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "MDDial.h"
#import "MDAttribute.h"

@implementation MDDial {
  MCStreamRequest *updateRequest_;
  BOOL valueUpdated_;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
  // model_property_name : json_field_name
  return @{
           @"dialChannel" : @"channel",
           @"dialValue" : @"value",
           @"dialAttributes" : @"attributes",
           @"dialName" : @"name",
           @"dialID" : @"dialID",
           @"isButtonDial" : @"isButtonDial",
           @"isRelative" : @"isRelative",
           @"isAutoCatch" : @"isAutoCatch",
           @"isInternalCommand" : @"isInternalCommand",
           @"internalCommandType" : @"internalCommandType",
           @"affectedDialChannel" : @"affectedDialChannel"
           };
}

+ (NSValueTransformer *)dialAttributesJSONTransformer
{
  // tell Mantle to populate diaAttributes property with an array of MDAttribute objects
  return [MTLJSONAdapter arrayTransformerWithModelClass:[MDAttribute class]];
}

- (void)updateDialValue:(NSNumber *)value {
  if (_dialValue.integerValue == value.integerValue && self.isButtonDial.integerValue == 0) {
    return;
  }
  _dialValue = value;
  
  if (self.isInternalCommand.boolValue) {
    return;
  }
  
  valueUpdated_ = YES;
  // Send to maya here.
  [self _sendUpdateIfNecessary];
}

- (void)setStopClientUpdates:(BOOL)stopClientUpdates {
  _stopClientUpdates = stopClientUpdates;
  [self _sendUpdateIfNecessary];
}

- (void)_sendUpdateIfNecessary {
  if (![[MCStreamClient sharedClient] isConnected] || self.stopClientUpdates) {
    return;
  }
  if (valueUpdated_ && updateRequest_ == nil) {
    valueUpdated_ = NO;
    NSString *pyCommand = [NSString stringWithFormat:@"midiConnect.md_update(%li, %li)", (long)self.dialChannel.integerValue, (long)self.dialValue.integerValue];
    
    __weak typeof(self) weakSelf = self;
    updateRequest_ = [[MCStreamClient sharedClient] sendPyCommand:pyCommand
                                                   withCompletion:^(NSString *returnString) {
                                                     __strong typeof(self) strongSelf = weakSelf;
                                                     [strongSelf _requestFinished:returnString];
                                                   } withFailure:^{
                                                     
                                                   }];
  }
}

- (void)_requestFinished:(NSString *)returnString {
  updateRequest_ = nil;
  [self _sendUpdateIfNecessary];
}

@end
