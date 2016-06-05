//
//  AppDelegate.m
//  midiConnect
//
//  Created by Brandon Withrow on 11/6/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//
#import "AppDelegate.h"
#import "MDMainViewController.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (nonatomic,strong) IBOutlet MDMainViewController *masterViewController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // Insert code here to initialize your application
  
  NSString *filePath = [[NSBundle mainBundle] pathForResource:@"JSONExample" ofType:@"json"];
  NSData *jsonData = [[NSData alloc] initWithContentsOfFile:filePath];

  id JSONObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:0 error:NULL];
  [NSFileManager saveJSONToApplicationSupportDirectory:JSONObject forFileName:@"JSONExample"];
  
  [[MCStreamClient sharedClient] startConnectionWithHost:@"127.0.0.1" andPort:4477];
  [[MDMidiManager sharedManager] connectToDevice:kDeviceName];
  
  self.masterViewController = [[MDMainViewController alloc] initWithNibName:@"MDMainViewController" bundle:nil];
  [self.window.contentView addSubview:self.masterViewController.view];
  self.masterViewController.view.frame = ((NSView*)self.window.contentView).bounds;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  [[[MDSceneManager sharedManager] currentScene] saveSceneToDisk];
}

@end
