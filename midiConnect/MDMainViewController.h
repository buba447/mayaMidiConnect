//
//  MDMainViewController.h
//  midiConnect
//
//  Created by Brandon Withrow on 11/16/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MDMainViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

// Header UI

@property (weak) IBOutlet NSButton *saveSceneButton;
@property (weak) IBOutlet NSButton *addNewSceneButton;
@property (weak) IBOutlet NSTextField *sceneNameTextField;
@property (weak) IBOutlet NSButton *addNewGroupButton;
@property (weak) IBOutlet NSButton *removeGroupButton;
@property (weak) IBOutlet NSPopUpButton *scenePicker;
@property (weak) IBOutlet NSPopUpButton *groupsPicker;

// Control Group UI

@property (weak) IBOutlet NSTextField *groupNameTextField;
@property (weak) IBOutlet NSTableView *controlsTableView;
@property (weak) IBOutlet NSButton *addNewControlButton;
@property (weak) IBOutlet NSButton *deleteControlButton;


// Control UI

@property (weak) IBOutlet NSTextField *controlNameTextField;
@property (weak) IBOutlet NSTextField *controlChannelTextFiel;
@property (weak) IBOutlet NSButton *controlListenButton;
@property (weak) IBOutlet NSButton *logSwitchButton;
@property (weak) IBOutlet NSTextField *childControlTextField;
@property (weak) IBOutlet NSButton *childControlListenButton;


// Attribute UI

@property (weak) IBOutlet NSTableView *attributesTableView;
@property (weak) IBOutlet NSButton *addNewAttributeButton;
@property (weak) IBOutlet NSButton *removeAttributeButton;
@property (weak) IBOutlet NSButton *loadFromMayaButton;

@property (weak) IBOutlet NSTextField *attributeNodeTextField;
@property (weak) IBOutlet NSTextField *attributeTextField;
@property (weak) IBOutlet NSTextField *melCommandTextField;

@property (weak) IBOutlet NSTextField *inputMinTextField;
@property (weak) IBOutlet NSTextField *inputMaxTextField;
@property (weak) IBOutlet NSTextField *outputMinTextField;
@property (weak) IBOutlet NSTextField *outputMaxTextField;
@property (weak) IBOutlet NSButton *refreshMinButton;
@property (weak) IBOutlet NSButton *refreshMaxButton;


// Connection UI
@property (strong) IBOutlet NSPopUpButton *deviceSelectionBox;
@property (weak) IBOutlet NSButton *mayaConnectButton;
@property (weak) IBOutlet NSTextField *mayaStatusField;

@end
