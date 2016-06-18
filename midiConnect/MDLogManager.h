//
//  MDLogManager.h
//  midiConnect
//
//  Created by Brandon Withrow on 6/6/16.
//  Copyright © 2016 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *kMDLogDidUpdate = @"logUpdated";

@interface MDLogManager : NSObject

@property (nonatomic, readonly) NSString *log;

+ (MDLogManager *)sharedManager;
- (void)log:(NSString *)message;

@end
