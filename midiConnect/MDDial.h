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

@property (nonatomic, copy) NSString *dialName;
@property (nonatomic, copy) NSNumber *dialChannel;
@property (nonatomic, copy) NSNumber *dialValue;
@property (nonatomic, copy) NSString *dialID;
@property (nonatomic, copy) NSArray<MDAttribute *> *dialAttributes;

// Bool that specifies if this is a log parent dial for another dial.
// Not really sure about these guys yet.
@property (nonatomic, copy) NSNumber *isLogDial;
@property (nonatomic, copy) NSNumber *parentDialChannel;
@property (nonatomic, copy) NSNumber *childDialChannel;

// This is model does the bulk of the actual work with maya.
// When the value is updated with the below method, it send a short command to maya
// It also queues its updates smartly to reduce input lag.
@property (nonatomic, assign) BOOL stopClientUpdates;
- (void)updateDialValue:(NSNumber *)value;

@end
