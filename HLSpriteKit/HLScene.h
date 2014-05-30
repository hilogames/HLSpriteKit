//
//  HLScene.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/21/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

/**
 * HLScene contains functionality useful to many scenes.
 *
 * TODO: Composition would be better than inheritance.  Can functionality
 * be grouped into modules or functions?  See, for instance, HLGestureScene,
 * which wants to offer a particular set of features to some (but not all)
 * scenes.
 */

@interface HLScene : SKScene

// Functionality for loading scene assets.

+ (void)loadSceneAssetsWithCompletion:(void(^)(void))completion;

+ (void)loadSceneAssets;

+ (BOOL)sceneAssetsLoaded;

+ (void)assertSceneAssetsLoaded;

@end
