//
//  HLMenuScene.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/29/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import "HLGestureScene.h"

@class HLMenuNode;
@class HLMessageNode;

/**
 * A simple scene implementation useful for a main menu.
 *
 * note: The core concept is less about a menu and more about a trivial scene with
 * only a few components (big smart subclassed nodes), such that the scene can
 * be instantiated and controlled "from the outside" rather than subclassed.  When
 * generalized into an "HLLayerScene" or some such thing, though, it tends to disappear
 * completely.  Revisit the idea later; what's the best way to provide common
 * scene functionality for trivial scenes?  Maybe it's always to create nodes, rather
 * than scenes, e.g. "HLMenuBackgroundMessageNode", and then always add just a single
 * node to the scene?  (That way, the nodes can always be recomposed as necessary.)
 * And then the single scene just supports (by parameters on pointers to nodes) any
 * needed functionality, e.g. archiving, and resizing some nodes on scene resize.
 *
 *     HLScene
 *     - (void)addChild:(SKNode *)child withOptions:(HLSceneChildOptions)options
 *
 *     HLSceneChildOptions
 *     + HLSceneChildNoCoding
 *     + HLSceneChildScaleToScene
 *     + HLSceneChildGestureTarget
 *     + HLSceneChildNoGestureTarget
 *
 * HERE HERE HERE this will work!  do it.  but...as part of HLScene, and then HLGesture
 * scene still inherits (and adds more options in addChild:withOptions:)?  Or maybe
 * collapse scene parents into each other and a big boolean flag for disabling gesture
 * handling?  Or maybe these scene parents are keeping track of everything that has been
 * added with a certain option, and gesture guys *always* are added with the special
 * addChild, and so we already know in HLScene that FLTrackScene deosn't want any options.
 * Or, all the way the other way: this is a new scene type, HLOptionScene, and HLGestureSCene
 * inherits from it (and overrides).  OR "HLSimpleScene" if the goal really is to have a
 * scene manageable from the outside.  (No....the goal is common functionality done easy.)
 */

@interface HLMenuScene : HLGestureScene <NSCoding>

@property (nonatomic, strong) SKSpriteNode *backgroundNode;

@property (nonatomic, strong) HLMenuNode *menuNode;

@property (nonatomic, strong) HLMessageNode *messageNode;

@end
