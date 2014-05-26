//
//  HLScene.m
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/21/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLScene.h"

static BOOL HLSceneAssetsLoaded = NO;

@implementation HLScene

+ (void)loadSceneAssetsWithCompletion:(void(^)(void))completion
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    [self loadSceneAssets];
    if (!completion) {
      return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      completion();
    });
  });
}

+ (void)loadSceneAssets
{
  // note: To be overridden by subclasses.
  HLSceneAssetsLoaded = YES;
}

+ (BOOL)sceneAssetsLoaded
{
  return HLSceneAssetsLoaded;
}

+ (void)assertSceneAssetsLoaded
{
  if (!HLSceneAssetsLoaded) {
    //[NSException raise:@"HLSceneAssetsNotLoaded" format:@"Scene assets not yet loaded."];
    NSLog(@"Scene assets not yet loaded!");
  }
}

@end
