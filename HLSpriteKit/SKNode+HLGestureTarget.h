//
//  SKNode+HLGestureTarget.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 2/4/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLGestureTarget.h"

/**
 A class category for attaching a gesture target to a node.
*/
@interface SKNode (HLGestureTarget)

/// @name Getting and Setting the Gesture Target

/**
 Returns the gesture target set by `hlSetGestureTarget:`, if any.
*/
- (id <HLGestureTarget>)hlGestureTarget;

/**
 Attaches a gesture target to (or detaches one from) this node.

 Presumably the gesture delegate (in the main scene or view) will detect when gestures
 intersect this node, and forward them to this attached gesture target.

 If the gesture target is the same object as the node, then the pointer to `self` is not
 explicitly retained (but will be returned by `hlGestureTarget`).

 Pass `nil` to unset the gesture target (if any).
*/
- (void)hlSetGestureTarget:(id <HLGestureTarget>)gestureTarget;

/**
 Attaches a gesture target to (or detaches one from) this node, without strongly
 retaining the gesture target.

 THIS VERSION IS FOR TEST AND EVALUATION.  The weak pointer is useful when the gesture
 target for a node is the controller of that node.  In that case, the controller
 (typically) retains the node, the node retains the gesture target, and the strong
 `hlSetGestureTarget` would retain the controller.  This version makes it so the node only
 keeps a weak link to the controller, so that when the controller is released, the node
 will also be released.

 If the gesture target is the same object as the node, then the pointer to `self` is not
 explicitly retained (but will be returned by `hlGestureTarget`).

 Pass `nil` to unset the gesture target (if any).
 */
- (void)hlSetWeakGestureTarget:(id <HLGestureTarget>)weakGestureTarget;

@end
