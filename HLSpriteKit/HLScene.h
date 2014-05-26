//
//  HLScene.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/21/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

@interface HLScene : SKScene

+ (void)loadSceneAssetsWithCompletion:(void(^)(void))completion;

+ (void)loadSceneAssets;

+ (BOOL)sceneAssetsLoaded;

+ (void)assertSceneAssetsLoaded;

@end
