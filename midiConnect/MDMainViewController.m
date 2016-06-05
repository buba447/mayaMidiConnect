//
//  MDMainViewController.m
//  midiConnect
//
//  Created by Brandon Withrow on 11/16/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "MDMainViewController.h"
#import "MDMirrorSheet.h"
@interface MDMainViewController ()
@property (nonatomic, readonly) MDSceneManager *sceneManager;
@property (nonatomic, strong) MDMirrorSheet *mirrorSheet;
@end

@implementation MDMainViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Ensure the scene manager is loaded
    [MDSceneManager sharedManager];
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
  self.attributeRangeTableView.dataSource = self;
  self.attributeRangeTableView.delegate = self;
  [self _updateUI];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDidEndForTableCell:) name:NSControlTextDidEndEditingNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internalCommandExecuted:) name:kMidiManagerInternalCommandDidExecute object:nil];
}

- (MDSceneManager *)sceneManager {
  return [MDSceneManager sharedManager];
}

- (void)goToNextScene {
  NSInteger idx = self.sceneManager.indexOfCurrentGroup;
  idx = [self loopingIndexOfObjectAtIndex:idx byAdding:1 count:self.sceneManager.currentScene.controlGroups.count];
  MDControlGroup *group = [self.sceneManager.currentScene.controlGroups objectAtIndex:idx];
  self.sceneManager.currentControlGroup = group;
  [self _updateGroupSection];
}

- (void)goToPreviousScene {
  NSInteger idx = self.sceneManager.indexOfCurrentGroup;
  idx = [self loopingIndexOfObjectAtIndex:idx byAdding:-1 count:self.sceneManager.currentScene.controlGroups.count];
  MDControlGroup *group = [self.sceneManager.currentScene.controlGroups objectAtIndex:idx];
  self.sceneManager.currentControlGroup = group;
  [self _updateGroupSection];
}

- (NSInteger)loopingIndexOfObjectAtIndex:(NSInteger)index byAdding:(NSInteger)add count:(NSInteger)count {
  if (labs(add) > count) {
    add = (add / labs(add)) * (labs(add) - count);
  }
  index += add;
  if (index >= count) {
    index -= count;
  }
  if (index < 0) {
    index += count;
  }
  return index;
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
  
  if (scene.midiDeviceName && [[[MDMidiManager sharedManager] availableDevices] containsObject:scene.midiDeviceName]) {
    [[MDMidiManager sharedManager] connectToDevice:scene.midiDeviceName];
  }
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

- (IBAction)buttonControlDidToggle:(id)sender {
  self.sceneManager.currentControl.isButtonDial = @(self.pushButtonToggle.integerValue);
  [self _updateControlSection];
}

- (IBAction)relativeControlDidToggle:(id)sender {
  self.sceneManager.currentControl.isRelative = @(self.relativeButtonToggle.integerValue);
  if (self.relativeButtonToggle.integerValue == 1) {
    self.sceneManager.currentControl.isAutoCatch = @0;
  }
  [self _updateControlSection];
}

- (IBAction)autoCatchControlDidToggle:(id)sender {
  self.sceneManager.currentControl.isAutoCatch = @(self.autoCatchButtonToggle.integerValue);
  [self _updateControlSection];
}

#pragma mark - Attribute UI Responders

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

- (IBAction)addRangeInputValue:(id)sender {
  MDDial *currentDial = self.sceneManager.currentControl;
  NSNumber *inputValue = currentDial.dialValue;
  
  if ([[MCStreamClient sharedClient] isConnected] == NO ||
      [[MDMidiManager sharedManager] isConnected] == NO) {
    // Maya or Midi arent connected
    // Set values to 0
    for (MDAttribute *attribute in self.sceneManager.currentAttributes) {
      if ([[MDMidiManager sharedManager] isConnected] == NO) {
        NSNumber *lastInput = attribute.inRange.lastObject;
        inputValue = @(lastInput.integerValue + 1);
      }
      [attribute setOutputValue:@0 forInputValue:inputValue];
    }
    [self _updateAttribueSection];
    return;
  }
  
  // Read from maya
  for (MDAttribute *attribute in self.sceneManager.currentAttributes) {
    if (attribute.mayaNode && attribute.mayaAttribute) {
      // Connected to maya and we have a node.attribute
      [[MCStreamClient sharedClient] sendPyCommand:[NSString stringWithFormat:@"cmds.getAttr('%@.%@')", attribute.mayaNode, attribute.mayaAttribute]
                                    withCompletion:^(NSString *response) {
                                      NSNumber *outputValue = @(response.floatValue);
                                      [attribute setOutputValue:outputValue forInputValue:inputValue];
                                      [self _updateAttribueSection];
                                    } withFailure:^{
                                      [self _updateAttribueSection];
                                    }];
    } else {
      // No node.attribute default to zero
      [attribute setOutputValue:@0 forInputValue:inputValue];
    }
  }

  [self _updateAttribueSection];
}

- (IBAction)removeInputRangeValue:(id)sender {
  NSInteger idx = [self.attributeRangeTableView selectedRow];
  for (MDAttribute *attribute in self.sceneManager.currentAttributes) {
    if (attribute.inRange.count > idx) {
      NSNumber *inputValue = attribute.inRange[idx];
      [attribute removeValueForInput:inputValue];
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
  self.sceneManager.currentScene.midiDeviceName = deviceName;
  [self _updateConnectionSection];
}

- (void)connectionStatusChanged:(NSNotification *)notif {
  [self _updateConnectionSection];
}

- (void)midiStatusChanged:(NSNotification *)notif {
  [self _updateConnectionSection];
}

- (IBAction)didUpdateAlwaysActive:(id)sender {
  self.sceneManager.currentControlGroup.isAlwaysActive = @(self.isAlwaysActiveGroup.integerValue);
  [self _updateGroupSection];
}

- (IBAction)dialTypeDidChange:(NSSegmentedControl *)sender {
  MDDial *dial = self.sceneManager.currentControl;
  dial.isInternalCommand = @(sender.selectedSegment);
  [self _updateControlSection];
}

- (IBAction)internalCommandTypeChanged:(NSPopUpButton *)sender {
  MDDial *dial = self.sceneManager.currentControl;
  switch (sender.selectedTag) {
    case 0:
      dial.internalCommandType = @"muteCommand";
      break;
    case 1:
      dial.internalCommandType = @"relativeCommand";
      break;
    case 2:
      dial.internalCommandType = @"nextButton";
      break;
    case 3:
      dial.internalCommandType = @"prevButton";
      break;
    default:
      break;
  }
  [self _updateControlSection];
}

- (IBAction)internalCommandListenForTargetChannel:(id)sender {
  MDDial *dial = self.sceneManager.currentControl;
  self.internalControlTargetTextField.backgroundColor = [NSColor redColor];
  [[MDMidiManager sharedManager] setMidiListeningBlock:^(NSNumber *channel) {
    dial.affectedDialChannel = channel;
    self.internalControlTargetTextField.backgroundColor = [NSColor whiteColor];
    [self _updateControlSection];
  }];
}


#pragma mark - Contextual Menu Responders

- (IBAction)controlTableDidSelectCopy:(id)sender {
  [self.sceneManager copyControlsToClipboard:@[self.sceneManager.currentControl]];
}

- (IBAction)controlTableDidSelectPaste:(id)sender {
  [self.sceneManager pasteControlsToGroup:self.sceneManager.currentControlGroup];
  [self _updateGroupSection];
}

- (IBAction)controlMenuDidSelectDuplicate:(id)sender {
  NSArray *previousClipboard = self.sceneManager.clipboardForControls;
  [self.sceneManager copyControlsToClipboard:@[self.sceneManager.currentControl]];
  [self.sceneManager pasteControlsToGroup:self.sceneManager.currentControlGroup];
  self.sceneManager.clipboardForControls = previousClipboard;
  [self _updateGroupSection];
}

- (IBAction)controlMenuDidSelectMirror:(id)sender {
  MDMirrorSheet *newMirrorSheet = [[MDMirrorSheet alloc] initWithNibName:@"MDMirrorSheet" bundle:nil];
  self.mirrorSheet = newMirrorSheet;
  [self presentViewControllerAsSheet:newMirrorSheet];
  [newMirrorSheet.cancelButton setTarget:self];
  [newMirrorSheet.cancelButton setAction:@selector(mirrorSheetDidSelectCancel:)];
  [newMirrorSheet.mirrorButton setTarget:self];
  [newMirrorSheet.mirrorButton setAction:@selector(mirrorSheetDidSelectMirror:)];
  newMirrorSheet.nameTextField.stringValue = self.sceneManager.currentControl.dialName;
}

- (IBAction)controlTableDidSelectDelete:(id)sender {
  [self deleteCurrentControlFromGroup:nil];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
  if (menuItem.menu == self.controlMenu) {
    NSInteger idx = [menuItem.menu indexOfItem:menuItem];
    switch (idx) {
      case 0: case 2: case 3: case 5: {
        return (self.controlsTableView.selectedRow >= 0);
      } break;
      case 1: {
        return (self.sceneManager.clipboardForControls.count > 0);
      } break;
    }
    return NO;
  }
  return YES;
}

#pragma mark - Mirror Sheet Responders

- (void)mirrorSheetDidSelectCancel:(id)sender {
  [self dismissViewController:self.mirrorSheet];
  self.mirrorSheet = nil;
}

- (void)mirrorSheetDidSelectMirror:(id)sender {
  [self.sceneManager mirrorControl:self.sceneManager.currentControl
                          withName:self.mirrorSheet.nameTextField.stringValue
                        findString:self.mirrorSheet.findTextField.stringValue
                     replaceString:self.mirrorSheet.replaceTextField.stringValue];
  [self _updateGroupSection];
  [self dismissViewController:self.mirrorSheet];
  self.mirrorSheet = nil;
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
  self.isAlwaysActiveGroup.integerValue = self.sceneManager.currentControlGroup.isAlwaysActive.integerValue;
}

- (void)_updateControlSection {
  MDDial *dial = self.sceneManager.currentControl;
  
  // Visibility
  if (dial.isInternalCommand.boolValue) {
    self.controlNameTextField.hidden = (dial == nil);
    self.controlChannelTextFiel.hidden = (dial == nil);
    self.controlListenButton.hidden = (dial == nil);
    self.pushButtonToggle.hidden = YES;
    self.attributesTableView.hidden = YES;
    self.addNewAttributeButton.hidden = YES;
    self.removeAttributeButton.hidden = YES;
    self.loadFromMayaButton.hidden = YES;
    self.relativeButtonToggle.hidden = YES;
    self.autoCatchButtonToggle.hidden = YES;
    self.attributesScrollView.hidden = YES;
    self.internalCommandSelector.hidden = NO;
    self.internalControlRefreshButton.hidden = NO;
    self.internalControlTargetTextField.hidden = NO;
  } else {
    self.controlNameTextField.hidden = (dial == nil);
    self.controlChannelTextFiel.hidden = (dial == nil);
    self.controlListenButton.hidden = (dial == nil);
    self.pushButtonToggle.hidden = (dial == nil);
    self.attributesScrollView.hidden = (dial == nil);
    self.attributesTableView.hidden = (dial == nil);
    self.addNewAttributeButton.hidden = (dial == nil);
    self.removeAttributeButton.hidden = (dial == nil);
    self.loadFromMayaButton.hidden = (dial == nil);
    self.relativeButtonToggle.hidden = (dial == nil);
    self.autoCatchButtonToggle.hidden = (dial == nil);
    self.internalCommandSelector.hidden = YES;
    self.internalControlRefreshButton.hidden = YES;
    self.internalControlTargetTextField.hidden = YES;
  }
  self.controlCommandTypeSelector.hidden = (dial == nil);
  
  // Data
  if (dial.internalCommandType.length) {
    if ([dial.internalCommandType isEqualToString:@"muteCommand"]) {
      [self.internalCommandSelector selectItemAtIndex:0];
    } else if ([dial.internalCommandType isEqualToString:@"prevButton"]) {
      [self.internalCommandSelector selectItemAtIndex:3];
    } else if ([dial.internalCommandType isEqualToString:@"nextButton"]) {
      [self.internalCommandSelector selectItemAtIndex:2];
    } else if ([dial.internalCommandType isEqualToString:@"relativeCommand"]) {
      [self.internalCommandSelector selectItemAtIndex:1];
    } else {
      [self.internalCommandSelector selectItemAtIndex:-1];
    }
  }
  
  [self.controlCommandTypeSelector setSelectedSegment:dial.isInternalCommand.integerValue];
  [self.internalControlTargetTextField setStringValue:dial.affectedDialChannel ? dial.affectedDialChannel.stringValue : @""];
  [self.controlNameTextField setStringValue:dial.dialName ?: @""];
  [self.controlChannelTextFiel setStringValue:dial.dialChannel ? dial.dialChannel.stringValue : @""];
  [self.pushButtonToggle setIntegerValue:dial.isButtonDial.integerValue];
  [self.relativeButtonToggle setIntegerValue:dial.isRelative.integerValue];
  [self.autoCatchButtonToggle setIntegerValue:dial.isAutoCatch.integerValue];
  self.autoCatchButtonToggle.enabled = (dial.isRelative.integerValue == 0);
  // TODO Remove log dials
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
  self.attributeAddRangeValueButton.hidden = (attribute == nil);
  self.attributeRemoveRangeValueButton.hidden = (attribute == nil);
  self.attributeRangeTableView.hidden = (attribute == nil);
  self.attributeRangeScrollView.hidden = (attribute == nil);
  //data
  self.attributeNodeTextField.stringValue = attribute.mayaNode ?: @"";
  self.attributeTextField.stringValue = attribute.mayaAttribute ?: @"";
  self.melCommandTextField.stringValue = attribute.mayaCommand ?: @"";

  [self.attributeRangeTableView reloadData];
  
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
  if (tableView == self.attributeRangeTableView &&
      self.sceneManager.currentAttributes.count) {
    return self.sceneManager.currentAttributes.lastObject.inRange.count;
  }
  return 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
  // Get a new ViewCell
  NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
  
  if (tableView == self.controlsTableView) {
    MDDial *control = [self.sceneManager.currentControlGroup.controls objectAtIndex:row];
    if (control.stopClientUpdates) {
      cellView.textField.textColor = [NSColor redColor];
    } else {
      cellView.textField.textColor = nil;
    }
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
    if (attribute.mayaCommand.length) {
      name = attribute.mayaCommand;
    } else if (attribute.mayaNode) {
      name = attribute.mayaAttribute ? [NSString stringWithFormat:@"%@.%@", attribute.mayaNode, attribute.mayaAttribute] : attribute.mayaNode;
    }
    cellView.textField.stringValue = name;
  }
  
  if (tableView == self.attributeRangeTableView) {
    MDAttribute *attr = self.sceneManager.currentAttributes.lastObject;
    if([tableColumn.identifier isEqualToString:@"inputValue"] ) {
      NSNumber *value = attr.inRange[row];
      cellView.textField.stringValue = [NSString stringWithFormat:@"%@", value];
    }
    if([tableColumn.identifier isEqualToString:@"outputValue"] ) {
      NSNumber *value = attr.outRange[row];
      cellView.textField.stringValue = [NSString stringWithFormat:@"%@", value];
    }
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

// Reordering
- (void)awakeFromNib {
  [self.attributesTableView registerForDraggedTypes:[NSArray arrayWithObject:@"NSMutableArray"]];
}

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard{
  // Copy the row numbers to the pasteboard.
  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
  
  [pboard declareTypes:[NSArray arrayWithObject:@"NSMutableArray"] owner:self];
  
  [pboard setData:data forType:@"NSMutableArray"];
  return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)op{
  // Add code here to validate the drop
  NSLog(@"validate Drop");
  return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)to dropOperation:(NSTableViewDropOperation)operation{
  
  NSMutableArray *attributes = [NSMutableArray arrayWithArray:self.sceneManager.currentControl.dialAttributes];
  //this is the code that handles dnd ordering - my table doesn't need to accept drops from outside! Hooray!
  NSPasteboard* pboard = [info draggingPasteboard];
  NSData* rowData = [pboard dataForType:@"NSMutableArray"];
  
  NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
  
  
  NSArray *objectsToMove = [attributes objectsAtIndexes:rowIndexes];

  MDAttribute *keystone = nil;
  if (to < attributes.count) {
    keystone = [attributes objectAtIndex:to];
  }
  NSInteger insertionIndex = NSNotFound;
  [attributes removeObjectsInArray:objectsToMove];
  if (keystone) {
    insertionIndex = [attributes indexOfObject:keystone];
  }
  
  for (MDAttribute *attribute in objectsToMove) {
    if (insertionIndex == NSNotFound) {
      [attributes addObject:attribute];
      continue;
    }
    [attributes insertObject:attribute atIndex:insertionIndex];
    insertionIndex ++;
  }
  self.sceneManager.currentControl.dialAttributes = attributes;
  [self.attributesTableView reloadData];
  return YES;
}

- (void)editingDidEndForTableCell:(NSNotification *)notif {
  NSTextField *textField = notif.object;
  double newValue = textField.doubleValue;
  NSInteger col = [self.attributeRangeTableView columnForView:textField];
  NSInteger row = [self.attributeRangeTableView rowForView:textField];
  
  
  MDAttribute *attribute = self.sceneManager.currentAttributes.lastObject;
  if (col == 0) {
    NSNumber *outValue = attribute.outRange[row];
    NSNumber *oldInput = attribute.inRange[row];
    [attribute removeValueForInput:oldInput];
    [attribute setOutputValue:outValue forInputValue:@(newValue)];
    [self _updateAttribueSection];
  } else if (col == 1) {
    NSNumber *inputValue = attribute.inRange[row];
    [attribute setOutputValue:@(newValue) forInputValue:inputValue];
    [self _updateAttribueSection];
  }
}

- (void)internalCommandExecuted:(NSNotification *)notif {
  NSString *commandType = notif.userInfo[@"type"];
  if ([commandType isEqualToString:@"muteCommand"]) {
    [self _updateGroupSection];
  } else if ([commandType isEqualToString:@"fineTuneCommand"]) {
    
  } else if ([commandType isEqualToString:@"prevButton"]) {
    [self goToPreviousScene];
  } else if ([commandType isEqualToString:@"nextButton"]) {
    [self goToNextScene];
  } else if ([commandType isEqualToString:@"relativeCommand"]) {
    [self _updateControlSection];
  }
}

@end
