//
//  MDMirrorSheet.h
//  midiConnect
//
//  Created by Brandon Withrow on 11/25/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MDMirrorSheet : NSViewController

@property (weak) IBOutlet NSButton *mirrorButton;
@property (weak) IBOutlet NSButton *cancelButton;
@property (weak) IBOutlet NSTextField *findTextField;
@property (weak) IBOutlet NSTextField *replaceTextField;
@property (weak) IBOutlet NSTextField *nameTextField;

@end
