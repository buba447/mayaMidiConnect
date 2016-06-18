//
//  MDLogManager.m
//  midiConnect
//
//  Created by Brandon Withrow on 6/6/16.
//  Copyright © 2016 Brandon Withrow. All rights reserved.
//

#import "MDLogManager.h"

static MDLogManager *sharedManager = nil;

@implementation MDLogManager {
  NSMutableString *_log;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _log = [NSMutableString string];
  }
  return self;
}

+ (MDLogManager *)sharedManager {
  if (!sharedManager) {
    sharedManager = [[MDLogManager alloc] init];
  }
  return sharedManager;
}

- (void)log:(NSString *)message {
  [_log appendString:message];
  [_log appendString:@"\n"];
  [[NSNotificationCenter defaultCenter] postNotificationName:kMDLogDidUpdate object:NULL];
}

-(NSString *)log {
  return _log;
}

@end
