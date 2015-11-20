//
//  MDMainViewController.m
//  midiConnect
//
//  Created by Brandon Withrow on 11/16/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "MDMainViewController.h"

@interface MDMainViewController ()
@property (nonatomic, readonly) MDSceneManager *sceneManager;
@end

@implementation MDMainViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectionStatusChanged:) name:kMayaConnectionStatusChanged object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(midiStatusChanged:) name:MIKMIDIDeviceWasAddedNotification object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(midiStatusChanged:) name:MIKMIDIDeviceWasRemovedNotification object:NULL];
  }
  return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.controlsTableView.dataSource = self;
  self.controlsTableView.delegate = self;
  self.attributesTableView.dataSource = self;
  self.attributesTableView.delegate = self;
  [self _updateUI];
}

- (MDSceneManager *)sceneManager {
  return [MDSceneManager sharedManager];
}

#pragma mark - Scene Management UI responders

- (IBAction)newScene:(id)sender {
  [[MDSceneManager sharedManager] createNewBlankScene];
  [self _updateUI];
}

- (IBAction)saveScene:(id)sender {
  [self.sceneManager.currentScene saveSceneToDisk];
  [self _updateUI];
}

- (IBAction)didSelectScene:(id)sender {
  NSInteger idx = self.scenePicker.indexOfSelectedItem;
  MDControlScene *scene = [self.sceneManager.allScenes objectAtIndex:idx];
  self.sceneManager.currentScene = scene;
  [self _updateUI];
}

- (IBAction)sceneNameChanged:(NSTextField *)sender {
  NSString *sceneName = [sender stringValue];
  self.sceneManager.currentScene.sceneName = sceneName;
  [self _updateUI];
}

#pragma mark - Group Managerment UI Responders

- (IBAction)addNewControlGroup:(id)sender {
  [self.sceneManager addNewGroupToCurrentScene];
  [self _updateUI];
}

- (IBAction)deleteCurrentControlGroup:(id)sender {
  [self.sceneManager deleteCurrentGroupFromScene];
  [self _updateUI];
}

- (IBAction)groupNameUpdated:(NSTextField *)sender {
  self.sceneManager.currentControlGroup.groupName = [sender stringValue];
  [self _updateUI];
}

- (IBAction)didSelectCurrentGroup:(id)sender {
  NSInteger idx = self.groupsPicker.indexOfSelectedItem;
  MDControlGroup *group = [self.sceneManager.currentScene.controlGroups objectAtIndex:idx];
  self.sceneManager.currentControlGroup = group;
  [self _updateUI];
}

- (IBAction)addNewControlToGroup:(id)sender {
  [self.sceneManager addNewControlToGroup];
  [self _updateUI];

}

- (IBAction)deleteCurrentControlFromGroup:(id)sender {
  MDDial *controlToDelete = self.sceneManager.currentControl;
  [self.sceneManager removeControlFromGroup:controlToDelete];
  [self _updateUI];
}

- (IBAction)controlNameUpdated:(id)sender {
  self.sceneManager.currentControl.dialName = self.controlNameTextField.stringValue;
  [self _updateGroupSection];
}

- (IBAction)startListeningForControlChannel:(id)sender {
  MDDial *dial = self.sceneManager.currentControl;
  self.controlChannelTextFiel.backgroundColor = [NSColor redColor];
  [[MDMidiManager sharedManager] setMidiListeningBlock:^(NSNumber *channel) {
    dial.dialChannel = channel;
    self.controlChannelTextFiel.backgroundColor = [NSColor whiteColor];
    [self _updateControlSection];
  }];
}

- (IBAction)logControlDidToggle:(id)sender {
  self.sceneManager.currentControl.isLogDial = @(self.logSwitchButton.integerValue);
  [self _updateControlSection];
}

- (IBAction)startListeningForChildControlChannel:(id)sender {
  MDDial *dial = self.sceneManager.currentControl;
  self.childControlTextField.backgroundColor = [NSColor redColor];
  [[MDMidiManager sharedManager] setMidiListeningBlock:^(NSNumber *channel) {
    [self.sceneManager linkControl:dial toChannel:channel isParent:YES];
    self.childControlTextField.backgroundColor = [NSColor whiteColor];
    [self _updateControlSection];
  }];
}

- (IBAction)addNewAttribute:(id)sender {
  [self.sceneManager addNewAttribute];
  [self _updateControlSection];
}

- (IBAction)removeSelectedAttributes:(id)sender {
  [self.sceneManager deleteCurrentAttributes];
  [self _updateControlSection];
}

- (IBAction)autoLoadAttributesFromMaya:(id)sender {
  [self.sceneManager createAttributesBaseOnMayaSelection:^{
    [self _updateUI];
  }];
}

- (IBAction)nodeNameDidUpdate:(id)sender {
  MDAttribute *attribute = self.sceneManager.currentAttributes.lastObject;
  attribute.mayaNode = self.attributeNodeTextField.stringValue;
  [self _updateControlSection];
}

- (IBAction)attributeNameDidUpdate:(id)sender {
  for (MDAttribute *attribute in self.sceneManager.currentAttributes) {
    attribute.mayaAttribute = self.attributeTextField.stringValue;
  }
  [self _updateControlSection];
}

- (IBAction)melCommandDidUpdate:(id)sender {
  for (MDAttribute *attribute in self.sceneManager.currentAttributes) {
    attribute.mayaCommand = self.melCommandTextField.stringValue;
  }
  [self _updateControlSection];
}

- (IBAction)inputMinDidUpdate:(id)sender {
  for (MDAttribute *attribute in self.sceneManager.currentAttributes) {
    attribute.inMinValue = @(self.inputMinTextField.integerValue);
  }
  [self _updateAttribueSection];
}

- (IBAction)outputMinDidUpdate:(id)sender {
  for (MDAttribute *attribute in self.sceneManager.currentAttributes) {
    attribute.outMinValue = @(self.outputMinTextField.floatValue);
  }
  [self _updateAttribueSection];
}

- (IBAction)recordInputOutputMin:(id)sender {
  MDDial *currentDial = self.sceneManager.currentControl;
  for (MDAttribute *attribute in self.sceneManager.currentAttributes) {
    attribute.inMinValue = currentDial.dialValue;
    if (attribute.mayaNode && attribute.mayaAttribute) {
      [[MCStreamClient sharedClient] sendPyCommand:[NSString stringWithFormat:@"cmds.getAttr('%@.%@')", attribute.mayaNode, attribute.mayaAttribute]
                                    withCompletion:^(NSString *response) {
                                      attribute.outMinValue = @(response.floatValue);
                                      [self _updateAttribueSection];
                                    } withFailure:^{
                                      [self _updateAttribueSection];
                                    }];
    }
  }
  
  [self _updateAttribueSection];
}

- (IBAction)inputMaxDidUpdate:(id)sender {
  for (MDAttribute *attribute in self.sceneManager.currentAttributes) {
    attribute.inMaxValue = @(self.inputMaxTextField.integerValue);
  }
  [self _updateAttribueSection];
}

- (IBAction)outputMaxDidUpdate:(id)sender {
  for (MDAttribute *attribute in self.sceneManager.currentAttributes) {
    attribute.outMaxValue = @(self.outputMaxTextField.floatValue);
  }
  [self _updateAttribueSection];
}

- (IBAction)recordInputOutputMax:(id)sender {
  MDDial *currentDial = self.sceneManager.currentControl;
  for (MDAttribute *attribute in self.sceneManager.currentAttributes) {
    attribute.inMaxValue = currentDial.dialValue;
    if (attribute.mayaNode && attribute.mayaAttribute) {
      [[MCStreamClient sharedClient] sendPyCommand:[NSString stringWithFormat:@"cmds.getAttr('%@.%@')", attribute.mayaNode, attribute.mayaAttribute]
                                    withCompletion:^(NSString *response) {
                                      attribute.outMaxValue = @(response.floatValue);
                                      [self _updateAttribueSection];
                                    } withFailure:^{
                                      [self _updateAttribueSection];
                                    }];
    }
  }
  
  [self _updateAttribueSection];
}

- (IBAction)didClickConnectButton:(id)sender {
  if ([[MCStreamClient sharedClient] isConnected]) {
    [[MCStreamClient sharedClient] disconnectFromHost];
  } else {
    [[MCStreamClient sharedClient] startConnectionWithHost:@"127.0.0.1" andPort:4477];
  }
  [self _updateConnectionSection];
}


- (IBAction)didSelectMidiDevice:(id)sender {
  NSInteger idx = self.deviceSelectionBox.indexOfSelectedItem;
  NSString *deviceName = [[[MDMidiManager sharedManager] availableDevices] objectAtIndex:idx];
  [[MDMidiManager sharedManager] connectToDevice:deviceName];
  [self _updateConnectionSection];
}

- (void)connectionStatusChanged:(NSNotification *)notif {
  [self _updateConnectionSection];
}

- (void)midiStatusChanged:(NSNotification *)notif {
  [self _updateConnectionSection];
}

#pragma mark - UI Updaters

- (void)_updateUI {
  // TODO Question this.
  [self _updateSceneHeader];
  [self _updateConnectionSection];
}

- (void)_updateSceneHeader {
  [self.scenePicker removeAllItems];
  [self.scenePicker addItemsWithTitles:self.sceneManager.allSceneNames];
  [self.scenePicker selectItemAtIndex:self.sceneManager.indexOfCurrentScene];
  [self.sceneNameTextField setStringValue:self.sceneManager.currentScene.sceneName];
  [self _updateGroupSection];
}

- (void)_updateGroupSection {
  [self.groupsPicker removeAllItems];
  [self.groupsPicker addItemsWithTitles:self.sceneManager.controlGroupNames];
  [self.groupsPicker selectItemAtIndex:self.sceneManager.indexOfCurrentGroup];
  self.groupNameTextField.stringValue = self.sceneManager.currentControlGroup.groupName ?: @"";
  [self.controlsTableView reloadData];
  // Reload Data clears selection.
  if (self.sceneManager.currentControl) {
    // Implicitly calls _updateControlSection
    [self.controlsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:self.sceneManager.indexOfCurrentControl] byExtendingSelection:NO];
  } else {
    [self _updateControlSection];
  }
}

- (void)_updateControlSection {
  MDDial *dial = self.sceneManager.currentControl;
  
  // Visibility
  self.controlNameTextField.hidden = (dial == nil);
  self.controlChannelTextFiel.hidden = (dial == nil);
  self.controlListenButton.hidden = (dial == nil);
  self.logSwitchButton.hidden = (dial == nil);
  self.childControlListenButton.hidden = (dial == nil);
  self.childControlTextField.hidden = (dial == nil);
  self.attributesTableView.hidden = (dial == nil);
  self.addNewAttributeButton.hidden = (dial == nil);
  self.removeAttributeButton.hidden = (dial == nil);
  self.loadFromMayaButton.hidden = (dial == nil);
  
  // Data
  [self.controlNameTextField setStringValue:dial.dialName ?: @""];
  [self.controlChannelTextFiel setStringValue:dial.dialChannel ? dial.dialChannel.stringValue : @""];
  [self.logSwitchButton setIntegerValue:dial.isLogDial.integerValue];
  self.childControlListenButton.enabled = (dial.isLogDial.integerValue == 1);
  if (dial.isLogDial.integerValue == 1) {
    self.childControlTextField.stringValue = dial.childDialChannel ? dial.childDialChannel.stringValue : @"";
  } else {
    self.childControlTextField.stringValue = @"";
  }
  
  [self.attributesTableView reloadData];
  // Reload Data clears selection.
  if (self.sceneManager.currentAttributes) {
    // Implicitly calls _updateAttributes
    [self.attributesTableView selectRowIndexes:self.sceneManager.indexesOfCurrentAttributes byExtendingSelection:NO];
  } else {
    [self _updateAttribueSection];
  }
}

- (void)_updateAttribueSection {
  MDAttribute *attribute = self.sceneManager.currentAttributes.lastObject;
  //Visibility
  self.attributeNodeTextField.hidden = (attribute == nil);
  self.attributeTextField.hidden = (attribute == nil);
  self.melCommandTextField.hidden = (attribute == nil);
  self.inputMaxTextField.hidden = (attribute == nil);
  self.inputMinTextField.hidden = (attribute == nil);
  self.outputMaxTextField.hidden = (attribute == nil);
  self.outputMinTextField.hidden = (attribute == nil);
  self.refreshMaxButton.hidden = (attribute == nil);
  self.refreshMinButton.hidden = (attribute == nil);
  
  //data
  self.attributeNodeTextField.stringValue = attribute.mayaNode ?: @"";
  self.attributeTextField.stringValue = attribute.mayaAttribute ?: @"";
  self.melCommandTextField.stringValue = attribute.mayaCommand ?: @"";
  self.inputMinTextField.stringValue = attribute.inMinValue ? attribute.inMinValue.stringValue : @"";
  self.inputMaxTextField.stringValue = attribute.inMaxValue ? attribute.inMaxValue.stringValue : @"";
  self.outputMinTextField.stringValue = attribute.outMinValue ? attribute.outMinValue.stringValue : @"";
  self.outputMaxTextField.stringValue = attribute.outMaxValue ? attribute.outMaxValue.stringValue : @"";
}

- (void)_updateConnectionSection {
  BOOL isConnected = [[MCStreamClient sharedClient] isConnected];
  NSString *mayaStatusString = isConnected ? @"Maya:Connected" : @"Maya:Disconnected";
  NSString *mayaButtonString = isConnected ? @"Disconnect" : @"Connect";
  NSColor *statusColor = isConnected ? [NSColor greenColor] : [NSColor redColor];
  
  self.mayaStatusField.stringValue = mayaStatusString;
  self.mayaStatusField.textColor = statusColor;
  self.mayaConnectButton.title = mayaButtonString;
  
  [self.deviceSelectionBox removeAllItems];
  NSArray *titles = [[MDMidiManager sharedManager] availableDevices];
  [self.deviceSelectionBox addItemsWithTitles:titles];
  [self.deviceSelectionBox selectItemWithTitle:[[MDMidiManager sharedManager] currentDevice]];
}

#pragma mark - Table Delegates

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
  if (tableView == self.controlsTableView) {
    return self.sceneManager.currentControlGroup.controls.count;
  }
  if (tableView == self.attributesTableView) {
    return self.sceneManager.currentControl.dialAttributes.count;
  }
  return 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  // Get a new ViewCell
  NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
  if (tableView == self.controlsTableView) {
    MDDial *control = [self.sceneManager.currentControlGroup.controls objectAtIndex:row];
    if([tableColumn.identifier isEqualToString:@"controlName"] ) {
      cellView.textField.stringValue = control.dialName ?: [NSString stringWithFormat:@"Untitled Control %li", (row + 1)];
    }
    if([tableColumn.identifier isEqualToString:@"controlChannel"] ) {
      cellView.textField.stringValue = [NSString stringWithFormat:@"%li", (long)control.dialChannel.integerValue];
    }

  }
  if (tableView == self.attributesTableView) {
    MDAttribute *attribute = [self.sceneManager.currentControl.dialAttributes objectAtIndex:row];
    NSString *name = @"Unassigned command";
    if (attribute.mayaCommand) {
      name = attribute.mayaCommand;
    } else if (attribute.mayaNode) {
      name = attribute.mayaAttribute ? [NSString stringWithFormat:@"%@.%@", attribute.mayaNode, attribute.mayaAttribute] : attribute.mayaNode;
    }
    cellView.textField.stringValue = name;
  }
  return cellView;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
  if (aNotification.object == self.controlsTableView) {
    NSInteger idx = self.controlsTableView.selectedRow;
    self.sceneManager.currentControl = (idx < 0 || idx >= self.sceneManager.currentControlGroup.controls.count) ? nil : [self.sceneManager.currentControlGroup.controls objectAtIndex:idx];
    [self _updateControlSection];
  } else if (aNotification.object == self.attributesTableView) {
    NSIndexSet *indexSet = self.attributesTableView.selectedRowIndexes;
    NSArray *attributes = [self.sceneManager.currentControl.dialAttributes objectsAtIndexes:indexSet];
    self.sceneManager.currentAttributes = attributes;
    [self _updateAttribueSection];
  }
}


@end
