//
//  LogicControl.h
//  ControlSurface
//
//  Created by Antonio "Willy" Malara on 05/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreMIDI/CoreMIDI.h>

@interface LogicControl : NSObject
{
	MIDIClientRef   client;
	
	MIDIEndpointRef source;
	MIDIEndpointRef destination;
	
	uint8_t         modelId;
	char            tcrCodeCString[13];
	char            stripTopCString[58];
	char            stripBottomCString[58];
}

@property(nonatomic, readonly)         NSString * name;
@property(nonatomic, readonly)         BOOL       online;

@property(nonatomic, retain, readonly) NSString * tcrCode;
@property(nonatomic, retain, readonly) NSString * stripTop;
@property(nonatomic, retain, readonly) NSString * stripBottom;

- (id)initWithName:(NSString *)name;

- (void)buttonPress:(uint8_t)buttonId;

@end
