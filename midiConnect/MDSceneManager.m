//
//  MDSceneManager.m
//  midiConnect
//
//  Created by Brandon Withrow on 11/10/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "MDSceneManager.h"

static MDSceneManager *sharedManager = nil;

@implementation MDSceneManager

+ (MDSceneManager *)sharedManager {
  if (!sharedManager) {
    sharedManager = [[MDSceneManager alloc] init];
  }
  return sharedManager;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    [self _scenesDirectoryTouched];
    self.currentScene = self.allScenes.firstObject;
  }
  return self;
}

#pragma mark - External Methods (OBJECT CREATION DELETION)

- (void)addNewGroupToCurrentScene {
  NSError *error;
  NSString *groupName = [NSString stringWithFormat:@"Group%lu", self.currentScene.controlGroups.count + 1];
  NSString *groupID = [self idForNewGroupInScene:self.currentScene];
  MDControlGroup *newGroup = [MTLJSONAdapter modelOfClass:[MDControlGroup class] fromJSONDictionary:@{@"name" : groupName, @"groupID" : groupID} error:&error];
  
  NSMutableArray *controlGroups = [NSMutableArray array];
  if (self.currentScene.controlGroups.count) {
    [controlGroups addObjectsFromArray:self.currentScene.controlGroups];
  }
  [controlGroups addObject:newGroup];
  self.currentScene.controlGroups = controlGroups;
  self.currentControlGroup = newGroup;
}

- (void)deleteCurrentGroupFromScene {
  if (!self.currentControlGroup) {
    return;
  }
  NSInteger idx = self.indexOfCurrentGroup;
  NSMutableArray *groups = [NSMutableArray arrayWithArray:self.currentScene.controlGroups];
  [groups removeObject:self.currentControlGroup];
  
  self.currentScene.controlGroups = groups;
  MDControlGroup *currentGroup = nil;
  if (idx >= groups.count) {
    idx = groups.count - 1;
  }
  if (groups.count) {
    currentGroup = [groups objectAtIndex:idx];
  }
  self.currentControlGroup = currentGroup;
}

- (void)addNewControlToGroup {
  NSString *controlName = @"Control";
  NSString *dedupedName = controlName;
  int count = 1;
  NSArray *nameArray = [self.currentControlGroup.controls valueForKeyPath:@"dialName"];
  while ([nameArray containsObject:dedupedName]) {
    dedupedName = [NSString stringWithFormat:@"%@%i", controlName, count];
    count ++;
  }
  NSString *controlID = [self idForNewControlInGroup:self.currentControlGroup];
  MDDial *newDial = [MTLJSONAdapter modelOfClass:[MDDial class] fromJSONDictionary:@{@"name" : dedupedName, @"dialID" : controlID} error:NULL];
  NSMutableArray *controls = [NSMutableArray array];
  if (self.currentControlGroup.controls) {
    [controls addObjectsFromArray:self.currentControlGroup.controls];
  }
  [controls addObject:newDial];
  self.currentControlGroup.controls = controls;
  self.currentControl = newDial;
}

- (void)removeControlFromGroup:(MDDial *)control {
  if (control == nil) {
    return;
  }
  if (self.currentControl == control) {
    self.currentControl = nil;
  }
  NSMutableArray *newArray = [NSMutableArray arrayWithArray:self.currentControlGroup.controls];
  [newArray removeObject:control];
  self.currentControlGroup.controls = newArray;
}

- (void)addNewAttribute {
  NSString *attributeID = [self idForNewAttributeInControl:self.currentControl];
  NSError *error;
  MDAttribute *attribute = [MTLJSONAdapter modelOfClass:[MDAttribute class] fromJSONDictionary:@{@"attributeID" : attributeID} error:&error];
  
  NSMutableArray *attributes = [NSMutableArray array];
  if (self.currentControl.dialAttributes) {
    [attributes addObjectsFromArray:self.currentControl.dialAttributes];
  }
  [attributes addObject:attribute];
  self.currentControl.dialAttributes = attributes;
}

- (void)addAttributes:(NSArray *)attributes {
  for (MDAttribute *attribute in attributes) {
    attribute.attributeID = [self idForNewAttributeInControl:self.currentControl];
    NSMutableArray *attributes = [NSMutableArray array];
    if (self.currentControl.dialAttributes) {
      [attributes addObjectsFromArray:self.currentControl.dialAttributes];
    }
    [attributes addObject:attribute];
    self.currentControl.dialAttributes = attributes;
  }
}

- (void)deleteCurrentAttributes {
  if (!self.currentAttributes) {
    return;
  }
  NSArray *currentAttributes = self.currentAttributes;
  NSMutableArray *attributes = [NSMutableArray arrayWithArray:self.currentControl.dialAttributes];
  [attributes removeObjectsInArray:currentAttributes];
  self.currentControl.dialAttributes = attributes;
  self.currentAttributes = nil;
}

#pragma mark - Property Overrides

-(NSArray<NSString *> *)controlGroupNames {
  NSMutableArray *groupNames = [NSMutableArray array];
  for (MDControlGroup *group in self.currentScene.controlGroups) {
    NSString *groupName = group.groupName ? : @"UNTITLED";
    NSString *deDupedGroupName = groupName;
    int count = 1;
    while ([groupNames containsObject:deDupedGroupName]) {
      deDupedGroupName = [NSString stringWithFormat:@"%@(%i)", groupName, count];
      count ++;
    }
    [groupNames addObject:deDupedGroupName];
    
  }
  return groupNames;
}

- (NSArray *)allSceneNames {
  NSMutableArray *sceneNames = [NSMutableArray array];
  for (MDControlScene *scene in self.allScenes) {
    NSString *sceneName = scene.sceneName ? : @"UNTITLED";
    NSString *deDupedSceneName = sceneName;
    int count = 1;
    while ([sceneNames containsObject:deDupedSceneName]) {
      deDupedSceneName = [NSString stringWithFormat:@"%@(%i)", sceneName, count];
      count ++;
    }
    [sceneNames addObject:deDupedSceneName];
  }
  return sceneNames;
}

- (void)setCurrentScene:(MDControlScene *)currentScene {
  _currentScene = currentScene;
  MDControlGroup *controlGroup = currentScene.controlGroups.firstObject;
  self.currentControlGroup = controlGroup;
}

- (void)setCurrentControlGroup:(MDControlGroup *)currentControlGroup {
  _currentControlGroup = currentControlGroup;
  self.currentControl = nil;
  if (currentControlGroup) {
    [self syncControlGroupWithMaya:currentControlGroup];
  }
}

- (void)setCurrentControl:(MDDial *)currentControl {
  _currentControl = currentControl;
  self.currentAttributes = nil;
}

- (NSInteger)indexOfCurrentGroup {
  if (!self.currentControlGroup || ![self.currentScene.controlGroups containsObject:self.currentControlGroup]) {
    return NSNotFound;
  }
  return [self.currentScene.controlGroups indexOfObject:self.currentControlGroup];
}

- (NSInteger)indexOfCurrentScene {
  if (!self.currentScene || ![self.allScenes containsObject:self.currentScene]) {
    return NSNotFound;
  }
  return [self.allScenes indexOfObject:self.currentScene];
}

- (NSInteger)indexOfCurrentControl {
  if (!self.currentControl || ![self.currentControlGroup.controls containsObject:self.currentControl]) {
    return NSNotFound;
  }
  return [self.currentControlGroup.controls indexOfObject:self.currentControl];
}

- (NSIndexSet *)indexesOfCurrentAttributes {
  NSMutableIndexSet *indexSet = [NSMutableIndexSet new];
  for (MDAttribute *attribute in self.currentAttributes) {
    [indexSet addIndex:[self.currentControl.dialAttributes indexOfObject:attribute]];
  }
  return indexSet;
}

#pragma mark - Midi Methods

- (MDDial *)dialForMidiChannel:(NSInteger)channel {
  for (MDDial *dial in self.currentControlGroup.controls) {
    if (dial.dialChannel.integerValue == channel) {
      return dial;
      break;
    }
  }
  for (MDControlGroup *group in self.currentScene.controlGroups) {
    if (group != self.currentControlGroup &&
        group.isAlwaysActive.integerValue == 1) {
      for (MDDial *dial in group.controls) {
        if (dial.dialChannel.integerValue == channel) {
          return dial;
          break;
        }
      }
    }
  }
  return nil;
}

#pragma mark - Maya Communication

- (void)syncControlGroupWithMaya:(MDControlGroup *)controlGroup {
  // Convert Control Group to JSON string.
  if (![[MCStreamClient sharedClient] isConnected]) return;

  NSError *error = nil;
  NSDictionary *jsonDictionary = [MTLJSONAdapter JSONDictionaryFromModel:controlGroup error:&error];
  if (error) {
    // TODO Handle
  }
  if (!jsonDictionary) {
    return;
  }
  
  // Now patch in always active controls
  NSMutableArray *jsonControls = nil;
  if (jsonDictionary[@"controls"]) {
    jsonControls = [NSMutableArray arrayWithArray:jsonDictionary[@"controls"]];
  } else {
    jsonControls = [NSMutableArray array];
  }

  BOOL controlsChanged = NO;
  for (MDControlGroup *group in self.currentScene.controlGroups) {
    if (group != controlGroup && group.isAlwaysActive.boolValue == 1) {
      controlsChanged = YES;
      NSError *error = nil;
      NSDictionary *activeDictionary = [MTLJSONAdapter JSONDictionaryFromModel:group error:&error];
      [jsonControls addObjectsFromArray:activeDictionary[@"controls"]];
    }
  }
  
  if (jsonControls.count && controlsChanged) {
    NSMutableDictionary *newJsonDictionary = [NSMutableDictionary dictionaryWithDictionary:jsonDictionary];
    newJsonDictionary[@"controls"] = jsonControls;
    jsonDictionary = newJsonDictionary;
  }
  
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary
                                                     options:0
                                                       error:&error];
  
  NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  jsonString = [jsonString stringByReplacingOccurrencesOfString:@"\n" withString:@""];
  NSString *strippedJson = [jsonString stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  NSString *command = [NSString stringWithFormat:@"midiConnect.updateControlGroup('%@')", strippedJson];
  [[MCStreamClient sharedClient] sendPyCommand:command withCompletion:^(NSString *completion) {
    NSLog(@"%@", completion);
  } withFailure:^{
    
  }];
}

#pragma mark - File Handling

- (NSString *)idForNewScene {
  NSString *newId = @"1";
  int count = 1;
  NSArray *allIds = [self.allScenes valueForKeyPath:@"sceneID"];
  while ([allIds containsObject:newId]) {
    count ++;
    newId = [NSString stringWithFormat:@"%i", count];
  }
  return newId;
}

- (NSString *)idForNewGroupInScene:(MDControlScene *)scene {
  NSString *newId = @"1";
  int count = 1;
  NSArray *allIds = [scene.controlGroups valueForKeyPath:@"groupID"];
  while ([allIds containsObject:newId]) {
    count ++;
    newId = [NSString stringWithFormat:@"%i", count];
  }
  return newId;
}

- (NSString *)idForNewControlInGroup:(MDControlGroup *)group {
  NSString *newId = @"1";
  int count = 1;
  NSArray *allIds = nil;
  if (group.controls) {
    allIds = [group.controls valueForKeyPath:@"dialID"];
  }
  while ([allIds containsObject:newId]) {
    count ++;
    newId = [NSString stringWithFormat:@"%i", count];
  }
  return newId;
}

- (NSString *)idForNewAttributeInControl:(MDDial *)control {
  NSString *newId = @"1";
  int count = 1;
  NSArray *allIds = nil;
  if (control) {
    allIds = [control.dialAttributes valueForKeyPath:@"attributeID"];
  }
  while ([allIds containsObject:newId]) {
    count ++;
    newId = [NSString stringWithFormat:@"%i", count];
  }
  return newId;
}

- (void)createNewBlankScene {
  if (self.currentScene) {
    [self.currentScene saveSceneToDisk];
    self.currentScene = nil;
  }
  
  NSString *sceneName = [NSFileManager fileNameForNewJsonFileNamed:@"Scene"];
  
  NSError *error;
  MDControlScene *newScene = [MTLJSONAdapter modelOfClass:[MDControlScene class] fromJSONDictionary:@{@"name" : sceneName, @"sceneID" : [self idForNewScene]} error:&error];
  
  NSMutableArray *allScenes = [NSMutableArray array];
  if (_allScenes) {
    [allScenes addObjectsFromArray:_allScenes];
  }
  [allScenes addObject:newScene];
  _allScenes = allScenes;
  
  self.currentScene = newScene;
  [self addNewGroupToCurrentScene];
}

- (void)_scenesDirectoryTouched {
  NSArray *allScenes = [MDControlScene loadAllScenesFromDisk];
  _allScenes = allScenes;
}

- (void)saveScene:(MDControlScene *)scene {
  NSError *error = nil;
  NSDictionary *jsonDictionary = [MTLJSONAdapter JSONDictionaryFromModel:scene error:&error];
  NSString *fileName = scene.sceneName ?: [NSFileManager fileNameForNewJsonFileNamed:@"Scene"];
  if (!error) {
    [NSFileManager saveJSONToApplicationSupportDirectory:jsonDictionary forFileName:fileName];
    [self _scenesDirectoryTouched];
  } else {
    NSLog(@"Error Saving");
  }
  if (self.currentControlGroup) {
    [self syncControlGroupWithMaya:self.currentControlGroup];
  }
}

- (void)createAttributesBaseOnMayaSelection:(void (^)(void))completion {
  [[MCStreamClient sharedClient] getNewAttributesFromSelectionWithCompletion:^(NSDictionary *response) {
    [self addNewAttributesFromMayaResponse:response];
    completion();
  } withFailure:^{
    completion();
  }];
}

- (void)addNewAttributesFromMayaResponse:(NSDictionary *)mayaResponse {
  if (!mayaResponse) {
    return;
  }
  NSMutableArray *newAttributes = [NSMutableArray array];
  id attrObject = mayaResponse[@"attributes"];
  NSArray *nodes = mayaResponse[@"objects"];
  for (NSDictionary *node in nodes) {
    NSString *nodeName = node.allKeys.firstObject;
    if ([attrObject isKindOfClass:[NSArray class]]) {
      NSArray *mayaAttr = (NSArray *)attrObject;
      for (NSString *attr in mayaAttr) {
        NSString *attributeID = [self idForNewAttributeInControl:self.currentControl];
        NSError *error;
        MDAttribute *attribute = [MTLJSONAdapter modelOfClass:[MDAttribute class] fromJSONDictionary:@{@"attributeID" : attributeID, @"mayaNode" : nodeName, @"mayaAttribute" : attr} error:&error];
        if (!error) {
          [newAttributes addObject:attribute];
        }
      }
    } else {
      NSString *attributeID = [self idForNewAttributeInControl:self.currentControl];
      NSError *error;
      MDAttribute *attribute = [MTLJSONAdapter modelOfClass:[MDAttribute class] fromJSONDictionary:@{@"attributeID" : attributeID, @"mayaNode" : nodeName} error:&error];
      if (!error) {
        [newAttributes addObject:attribute];
      }
    }
    
  }
  if (newAttributes.count) {
    [self addAttributes:newAttributes];
  }
}

#pragma mark - Clipboard

- (void)copyControlsToClipboard:(NSArray<MDDial *> *)controls {
  NSMutableArray *newClipboard = [NSMutableArray array];
  for (MDDial *dial in controls) {
    // For simplicity, serialize objects and store.
    NSError *error = nil;
    NSDictionary *jsonDictionary = [MTLJSONAdapter JSONDictionaryFromModel:dial error:&error];
    if (jsonDictionary && !error) {
      [newClipboard addObject:jsonDictionary];
    }
  }
  self.clipboardForControls = newClipboard;
}

- (void)pasteControlsToGroup:(MDControlGroup *)controlGroup {
  NSMutableArray *controls = [NSMutableArray array];
  if (controlGroup.controls.count) {
    [controls addObjectsFromArray:controlGroup.controls];
  }
  for (NSDictionary *dictionary in self.clipboardForControls) {
    NSError *error = nil;
    MDDial *newControl = [MTLJSONAdapter modelOfClass:[MDDial class] fromJSONDictionary:dictionary error:&error];
    if (newControl && !error) {
      newControl.dialID = [self idForNewControlInGroup:controlGroup];
      [controls addObject:newControl];
    }
  }
  controlGroup.controls = controls;
}

- (void)mirrorControl:(MDDial *)control withName:(NSString *)newName findString:(NSString *)findString replaceString:(NSString *)replaceString {
  NSError *error = nil;
  NSDictionary *jsonDictionary = [MTLJSONAdapter JSONDictionaryFromModel:control error:&error];
  MDDial *newControl = [MTLJSONAdapter modelOfClass:[MDDial class] fromJSONDictionary:jsonDictionary error:&error];
  newControl.dialName = newName ?: [NSString stringWithFormat:@"%@ mirrored", newControl.dialName];
  if (findString.length && replaceString.length) {
    for (MDAttribute *attr in newControl.dialAttributes) {
      attr.mayaNode = [attr.mayaNode stringByReplacingOccurrencesOfString:findString withString:replaceString];
    }
  }
  
  NSMutableArray *controls = [NSMutableArray array];
  if (self.currentControlGroup.controls.count) {
    [controls addObjectsFromArray:self.currentControlGroup.controls];
  }
  [controls addObject:newControl];
  self.currentControlGroup.controls = controls;
}

@end
