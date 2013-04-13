//
//  AppDelegate.m
//  Control Surface
//
//  Created by Antonio Malara on 4/14/13.
//  Copyright (c) 2013 Antonio Malara. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "LogicControl.h"

@implementation AppDelegate
{
    LogicControl   * logicControl;
    ViewController * viewController;
    UIWindow       * window;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
{
    logicControl = [[LogicControl alloc] initWithName:@"Control Surface"];
        
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        viewController = [[ViewController alloc] initWithNibName:@"ViewController_iPhone" bundle:nil];
    else
        viewController = [[ViewController alloc] initWithNibName:@"ViewController_iPad" bundle:nil];
    
    window.rootViewController = viewController;
    [window makeKeyAndVisible];
    
    return YES;
}

@end
