//
//  MDMidiManager.h
//  midiConnect
//
//  Created by Brandon Withrow on 11/9/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *kMidiManagerInternalCommandDidExecute = @"mdInternalCommand";

@interface MDMidiManager : NSObject

+ (MDMidiManager *)sharedManager;

@property (nonatomic, strong, readonly) NSArray<NSString*> *availableDevices;
@property (nonatomic, copy) void (^midiListeningBlock)(NSNumber *midiChannel);
@property (nonatomic, readonly) NSString *currentDevice;
@property (nonatomic, readonly) BOOL isConnected;

- (void)connectToDevice:(NSString *)deviceName;

@end
