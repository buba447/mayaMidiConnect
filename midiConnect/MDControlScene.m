//
//  MDControlScene.m
//  midiConnect
//
//  Created by Brandon Withrow on 11/6/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "MDControlScene.h"
#import "MDControlGroup.h"

@implementation MDControlScene

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
  return @{@"sceneName" : @"name",
           @"controlGroups" : @"groups",
           @"sceneID" : @"sceneID",
           @"midiDeviceName" : @"midiDeviceName"};
}

+ (NSValueTransformer *)controlGroupsJSONTransformer {
  // tell Mantle to populate diaAttributes property with an array of MDAttribute objects
  return [MTLJSONAdapter arrayTransformerWithModelClass:[MDControlGroup class]];
}

+ (NSArray *)loadAllScenesFromDisk {
  NSArray *jsonIds = [NSFileManager loadAllJSONFilesFromDirectory:nil];
  NSError *error;
  NSMutableArray *returnArray = [NSMutableArray array];
  for (id object in jsonIds) {
    if ([object isKindOfClass:[NSArray class]]) {
      NSArray *scenes = [MTLJSONAdapter modelsOfClass:[MDControlScene class] fromJSONArray:object error:&error];
      if (!error) {
        [returnArray addObjectsFromArray:scenes];
      }
    } else if ([object isKindOfClass:[NSDictionary class]]) {
      MDControlScene *scene = [MTLJSONAdapter modelOfClass:[MDControlScene class] fromJSONDictionary:object error:&error];
      if (!error) {
        [returnArray addObject:scene];
      }
    }
    error = nil;
  }
  return returnArray;
}

+ (MDControlScene *)loadSceneFromDiskNamed:(NSString *)name {
  id jsonObject = [NSFileManager loadJSONFromApplicationSupportDirectoryForName:name];
  MDControlScene *controlScene = nil;
  if ([jsonObject isKindOfClass:[NSDictionary class]]) {
    NSError *error;
    controlScene = [MTLJSONAdapter modelOfClass:[MDControlScene class] fromJSONDictionary:jsonObject error:&error];
  }
  return controlScene;
}

- (void)saveSceneToDisk {
  [[MDSceneManager sharedManager] saveScene:self];
}

@end
