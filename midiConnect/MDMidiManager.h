//
//  MDMidiManager.h
//  midiConnect
//
//  Created by Brandon Withrow on 11/9/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MDMidiManager : NSObject

+ (MDMidiManager *)sharedManager;

@property (nonatomic, strong, readonly) NSArray<NSString*> *availableDevices;
@property (nonatomic, copy) void (^midiListeningBlock)(NSNumber *midiChannel);
@property (nonatomic, readonly) NSString *currentDevice;

- (void)connectToDevice:(NSString *)deviceName;

@end
