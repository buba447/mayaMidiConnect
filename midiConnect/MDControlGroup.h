//
//  MDControlGroup.h
//  midiConnect
//
//  Created by Brandon Withrow on 11/6/15.
//  Copyright © 2015 Brandon Withrow. All rights reserved.
//

#import "MTLModel.h"
@class MDDial;

@interface MDControlGroup : MTLModel <MTLJSONSerializing>

@property (nonatomic, copy) NSString *groupName;
@property (nonatomic, copy) NSString *groupID;
@property (nonatomic, copy) NSNumber *isAlwaysActive;
@property (nonatomic, copy) NSArray<MDDial *> *controls;

@end
