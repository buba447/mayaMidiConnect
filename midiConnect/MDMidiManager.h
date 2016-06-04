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

// TODO Move Special cases into a commands class.
- (void)addSpecialCaseBlock:(void (^)(void))specialBlock forChannelNumber:(NSNumber *)channelNumber;
- (void)removeAllSpecialCaseBlocks;

- (void)connectToDevice:(NSString *)deviceName;

@end
