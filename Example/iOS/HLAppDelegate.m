//
//  HLAppDelegate.m
//  HLSpriteKit
//
//  Created by CocoaPods on 11/14/2014.
//  Copyright (c) 2014 Karl Voskuil. All rights reserved.
//

#import "HLAppDelegate.h"

#import "HLViewController.h"

@implementation HLAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.backgroundColor = [UIColor whiteColor];
  
  HLViewController *rootViewController = [[HLViewController alloc] init];
  self.window.rootViewController = rootViewController;
  
  [self.window makeKeyAndVisible];
  return YES;
}
							
@end
