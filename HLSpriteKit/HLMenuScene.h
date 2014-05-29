//
//  HLMenuScene.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/29/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <HLSpriteKit/HLSpriteKit.h>

/**
 * A simple scene implementation useful for a main menu.
 *
 * note: The core concept is less about a menu and more about a simple scene
 * which can be instantiated as-is rather than subclassed.  When generalized
 * into an "HLLayerScene" or some such thing, though, it tends to disappear
 * completely.  Revisit the idea later; what's the best way to provide common
 * scene functionality?
 */

@interface HLMenuScene : HLGestureScene <NSCoding>

@property (nonatomic, strong) HLMenuNode *menuNode;

@property (nonatomic, strong) SKSpriteNode *backgroundNode;

@end
