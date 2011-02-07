//
//  ControlSurfaceAppDelegate.h
//  ControlSurface
//
//  Created by Antonio "Willy" Malara on 05/02/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LogicControl.h"

@interface ControlSurfaceAppDelegate : NSObject <NSApplicationDelegate>

@property(nonatomic, assign) IBOutlet NSWindow * window;
@property(nonatomic, retain) LogicControl * logicControl;

- (IBAction)pressButton:(NSButton *)sender;

@end
