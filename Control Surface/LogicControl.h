//
//  LogicControl.h
//  ControlSurface
//
//  Created by Antonio "Willy" Malara on 05/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LogicControl : NSObject

@property(nonatomic, readonly)         NSString * name;
@property(nonatomic, readonly)         BOOL       online;

@property(nonatomic, retain, readonly) NSString * tcrCode;
@property(nonatomic, retain, readonly) NSString * stripTop;
@property(nonatomic, retain, readonly) NSString * stripBottom;

- (id)initWithName:(NSString *)name;

- (void)buttonPress:(uint8_t)buttonId;

@end
