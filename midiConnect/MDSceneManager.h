//
//  MDSceneManager.h
//  midiConnect
//
//  Created by Brandon Withrow on 11/10/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MDSceneManager : NSObject

+ (MDSceneManager *)sharedManager;

@property (nonatomic, strong) MDControlScene *currentScene;
@property (nonatomic, strong) MDControlGroup *currentControlGroup;
@property (nonatomic, strong) MDDial *currentControl;
@property (nonatomic, strong) NSArray<MDAttribute *> *currentAttributes;

@property (nonatomic, readonly) NSArray *allScenes;
@property (nonatomic, readonly) NSArray *allSceneNames;
@property (nonatomic, readonly) NSArray<NSString *> *controlGroupNames;
@property (nonatomic, readonly) NSInteger indexOfCurrentGroup;
@property (nonatomic, readonly) NSInteger indexOfCurrentScene;
@property (nonatomic, readonly) NSInteger indexOfCurrentControl;
@property (nonatomic, readonly) NSIndexSet *indexesOfCurrentAttributes;
@property (nonatomic, strong) NSArray *clipboardForControls;

- (void)copyControlsToClipboard:(NSArray<MDDial *> *)controls;
- (void)pasteControlsToGroup:(MDControlGroup *)controlGroup;
- (void)mirrorControl:(MDDial *)control withName:(NSString *)newName findString:(NSString *)findString replaceString:(NSString *)replaceString;

- (void)addNewGroupToCurrentScene;
- (void)deleteCurrentGroupFromScene;
- (void)addNewControlToGroup;
- (void)removeControlFromGroup:(MDDial *)control;
- (void)addNewAttribute;
- (void)addAttributes:(NSArray *)attributes;
- (void)deleteCurrentAttributes;

- (void)createNewBlankScene;
- (void)saveScene:(MDControlScene *)scene;

- (MDDial *)dialForMidiChannel:(NSInteger)channel;
- (void)syncControlGroupWithMaya:(MDControlGroup *)controlGroup;

- (void)createAttributesBaseOnMayaSelection:(void (^)(void))completion;

@end
