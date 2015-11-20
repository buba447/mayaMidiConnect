//
//  MDMidiManager.m
//  midiConnect
//
//  Created by Brandon Withrow on 11/9/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "MDMidiManager.h"
#import "MDSceneManager.h"

@interface MDMidiManager ()

@property (nonatomic, strong) MIKMIDIDevice *controlDevice;
@property (nonatomic, strong) NSMapTable *connectionTokensForSources;

@end

static MDMidiManager *sharedManager = nil;

@implementation MDMidiManager

- (id)init {
  self = [super init];
  if (self) {
    self.connectionTokensForSources = [NSMapTable strongToStrongObjectsMapTable];
  }
  return self;
}

+ (MDMidiManager *)sharedManager {
  if (!sharedManager) {
    sharedManager = [[MDMidiManager alloc] init];
  }
  return sharedManager;
}

- (NSArray<NSString *> *)availableDevices {
  NSArray *availableMIDIDevices = [[MIKMIDIDeviceManager sharedDeviceManager] availableDevices];
  return [availableMIDIDevices valueForKeyPath:@"name"];
}

- (NSString *)currentDevice {
  return self.controlDevice.model;
}

- (void)connectToDevice:(NSString *)deviceName {
  [self disconnectDevice];
  NSArray *availableMIDIDevices = [[MIKMIDIDeviceManager sharedDeviceManager] availableDevices];
  for (MIKMIDIDevice *device in availableMIDIDevices) {
    if ([device.name isEqualToString:deviceName]) {
      self.controlDevice = device;
    }
  }
  if (self.controlDevice) {
    NSArray *sources = [self.controlDevice.entities valueForKeyPath:@"@unionOfArrays.sources"];
    for (MIKMIDISourceEndpoint *source in sources) {
      NSError *error = nil;
      id connectionToken = [[MIKMIDIDeviceManager sharedDeviceManager] connectInput:source error:&error eventHandler:^(MIKMIDISourceEndpoint *source, NSArray *commands) {
        for (MIKMIDIChannelVoiceCommand *command in commands) { [self _handleMIDICommand:command]; }
      }];
      if (!connectionToken) {
        NSLog(@"Unable to connect to input: %@", error);
      } else {
        [self.connectionTokensForSources setObject:connectionToken forKey:source];
      }
    }
  }
}

- (void)disconnectDevice {
  NSArray *sources = [self.controlDevice.entities valueForKeyPath:@"@unionOfArrays.sources"];
  for (MIKMIDISourceEndpoint *source in sources) {
    id token = [self.connectionTokensForSources objectForKey:source];
    [self.connectionTokensForSources removeObjectForKey:source];
    if (!token) continue;
    [[MIKMIDIDeviceManager sharedDeviceManager] disconnectInput:source forConnectionToken:token];
    
  }
}

- (void)setMidiListeningBlock:(void (^)(NSNumber *))midiListeningBlock {
  if (_midiListeningBlock) {
    _midiListeningBlock(nil);
  }
  _midiListeningBlock = midiListeningBlock;
}

- (void)_handleMIDICommand:(MIKMIDICommand *)command {
  if (self.midiListeningBlock) {
    self.midiListeningBlock(@([(MIKMIDIControlChangeCommand *)command controllerNumber]));
    _midiListeningBlock = nil;
    return;
  }
  NSInteger controlChannel = [(MIKMIDIControlChangeCommand *)command controllerNumber];
  MDDial *dial = [[MDSceneManager sharedManager] dialForMidiChannel:controlChannel];
  if (dial) {
    NSInteger value = [(MIKMIDIControlChangeCommand *)command controllerValue];
    [dial updateDialValue:@(value)];
  }
}

@end