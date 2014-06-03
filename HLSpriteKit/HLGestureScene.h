//
//  HLGestureScene.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/27/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLScene.h"
#import "HLGestureTarget.h"

/**
 * HLGestureScene implements a gesture handler for any of its child nodes which
 * conform to HLGestureTarget, and associated common functionality which depends
 * on gesture targets.
 *
 * note: This is a feature useful to different kinds of scenes; consider making
 * this a component for composition rather than a class for subclassing.
 *
 * note: The scene will add gesture recognizers dynamically as children are
 * added, but will not remove them when children are removed.
 */

@interface HLGestureScene : HLScene <UIGestureRecognizerDelegate>

/**
 * Presents a node modally above the current scene, disabling other interaction.
 *
 * note: "Above" the current scene might or might not depend on (a particular) zPosition,
 * depending on whether the SKView ignoresSiblingOrder.  It's left to the caller to
 * provide an appropriate zPosition range that can be used by this scene to display
 * the presented node and other related decorations and animations.  The presented
 * node will have its zPosition set to a value in the provided range, but exactly
 * what value is implementation-specific.  The range may be empty; that is, min and
 * max may be the same.
 *
 * @param The node to present modally.  If the node or any of its children are HLGestureTargets
 *        then the HLGestureScene's gesture handling code will forward gestures to the it.
 *        (The scene will not otherwise automatically dismiss the presented node; perhaps the
 *        node will dismiss itself, or perhaps the node has a delegate which will dismiss it.)
 *
 * @param A lower bound (inclusive) for a range of zPositions to be used by the presented
 *        node and other related decorations and animations.  See note above.
 *
 * @param An upper bound (inclusive) for a range of zPositions to be used by the presented
 *        node and other related decorations and animations.  See note above.
 */
- (void)presentModalNode:(SKNode *)node
            zPositionMin:(CGFloat)zPositionMin
            zPositionMax:(CGFloat)zPositionMax;

/**
 * Dismisses the node currently presented by presentModalNode (if any).
 */
- (void)dismissModalNode;

@end
