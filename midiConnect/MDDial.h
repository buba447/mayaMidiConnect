//
//  MDDial.h
//  midiConnect
//
//  Created by Brandon Withrow on 11/6/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "MTLModel.h"
@class MDAttribute;

@interface MDDial : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy) NSString *dialID;
@property (nonatomic, copy) NSString *dialName;
@property (nonatomic, copy) NSNumber *dialChannel;
@property (nonatomic, copy) NSNumber *dialValue;
@property (nonatomic, copy) NSNumber *isButtonDial;
@property (nonatomic, copy) NSNumber *isRelative;
@property (nonatomic, copy) NSNumber *isAutoCatch;

@property (nonatomic, copy) NSArray<MDAttribute *> *dialAttributes;

@property (nonatomic, copy) NSNumber *isInternalCommand;
@property (nonatomic, copy) NSString *internalCommandType;
@property (nonatomic, copy) NSNumber *affectedDialChannel;

// This is model does the bulk of the actual work with maya.
// When the value is updated with the below method, it send a short command to maya
// It also queues its updates smartly to reduce input lag.
@property (nonatomic, assign) BOOL stopClientUpdates;
- (void)updateDialValue:(NSNumber *)value;

@end
