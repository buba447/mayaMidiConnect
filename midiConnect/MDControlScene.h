//
//  MDControlScene.h
//  midiConnect
//
//  Created by Brandon Withrow on 11/6/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "MTLModel.h"
@class MDControlGroup;
@interface MDControlScene : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy) NSString *sceneID;
@property (nonatomic, copy) NSString *sceneName;
@property (nonatomic, copy) NSString *midiDeviceName;
@property (nonatomic, copy) NSArray<MDControlGroup *> *controlGroups;

+ (NSArray *)loadAllScenesFromDisk;
+ (MDControlScene *)loadSceneFromDiskNamed:(NSString *)name;
- (void)saveSceneToDisk;

@end
