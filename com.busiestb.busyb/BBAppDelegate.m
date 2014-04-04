//
//  BBAppDelegate.m
//  com.busiestb.busyb
//
//  Created by Kevin Greene on 3/30/14.
//  Copyright (c) 2014 Kevin Greene. All rights reserved.
//

#import "BBAppDelegate.h"

#import "BBHiveViewController.h"

@implementation BBAppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.rootViewController = [[BBHiveViewController alloc] init];
  [self.window makeKeyAndVisible];
  return YES;
}

@end
