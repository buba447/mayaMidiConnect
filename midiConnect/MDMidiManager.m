//
//  MDMidiManager.m
//  midiConnect
//
//  Created by Brandon Withrow on 11/9/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "MDMidiManager.h"
#import "MDSceneManager.h"
#import "MDLogManager.h"

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
        [[MDLogManager sharedManager] log:[NSString stringWithFormat:@"Unable to connect to input: %@", error]];
      } else {
        _isConnected = YES;
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
  _isConnected = NO;
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
  
  NSInteger value = NSNotFound;
  NSInteger controlChannel = NSNotFound;
  if ([command isKindOfClass:[MIKMIDIControlChangeCommand class]]) {
    value = [(MIKMIDIControlChangeCommand *)command controllerValue];
    controlChannel = [(MIKMIDIControlChangeCommand *)command controllerNumber];
  }
  
  if ([command isKindOfClass:[MIKMIDINoteOnCommand class]]) {
    value = [(MIKMIDINoteOnCommand *)command velocity];
    controlChannel = [(MIKMIDINoteOnCommand *)command note];
  }
  
  if ([command isKindOfClass:[MIKMIDINoteOffCommand class]]) {
    value = 0;
    controlChannel = [(MIKMIDINoteOffCommand *)command note];
  }
  
  if (value == NSNotFound || controlChannel == NSNotFound) {
    return;
  }
  
  MDDial *dial = [[MDSceneManager sharedManager] dialForMidiChannel:controlChannel];
  
  if (dial.isInternalCommand.boolValue &&
      dial.internalCommandType.length) {
    [dial updateDialValue:@(value)];
    [self _handInternalCommandDial:dial];
    return;
  }
  
  if (dial && dial.isButtonDial.integerValue == 1) {
    if (value == 127) {
      [dial updateDialValue:@(value)];
    }
    return;
  }
  
  if (dial) {
    [dial updateDialValue:@(value)];
  } else {
    [[MDLogManager sharedManager] log:[NSString stringWithFormat:@"Error: No attributes found for channel %li", (long)controlChannel]];
  }
}

- (void)_handInternalCommandDial:(MDDial *)commandDial {
  MDDial *affectingDial = nil;
  NSDictionary *userInfo = @{@"type" : commandDial.internalCommandType};
  
  if (commandDial.affectedDialChannel) {
    affectingDial = [[MDSceneManager sharedManager] dialForMidiChannel:commandDial.affectedDialChannel.integerValue];
  }
  
  if ([commandDial.internalCommandType isEqualToString:@"muteCommand"]) {
    affectingDial.muteDial = (commandDial.dialValue.integerValue > 0);
  } else if ([commandDial.internalCommandType isEqualToString:@"fineTuneCommand"]) {
    
  } else if ([commandDial.internalCommandType isEqualToString:@"prevButton"]) {
    if (commandDial.dialValue.integerValue > 0) {
      userInfo = nil;
    }
  } else if ([commandDial.internalCommandType isEqualToString:@"nextButton"]) {
    if (commandDial.dialValue.integerValue > 0) {
      userInfo = nil;
    }
  } else if ([commandDial.internalCommandType isEqualToString:@"relativeCommand"] && commandDial.dialValue.integerValue == 0) {
    affectingDial.isRelative = affectingDial.isRelative.boolValue ? @0 : @1;
  }
  
  
  [[NSNotificationCenter defaultCenter] postNotificationName:kMidiManagerInternalCommandDidExecute object:NULL userInfo:userInfo];
}

@end
