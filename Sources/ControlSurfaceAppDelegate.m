//
//  ControlSurfaceAppDelegate.m
//  ControlSurface
//
//  Created by Antonio "Willy" Malara on 05/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ControlSurfaceAppDelegate.h"

@implementation ControlSurfaceAppDelegate

@synthesize window;
@synthesize logicControl;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
{
	self.logicControl = [[LogicControl new] autorelease];
}

- (IBAction)pressButton:(NSButton *)sender;
{
	[self.logicControl buttonPress:(uint8_t)[sender tag]];
}

@end
