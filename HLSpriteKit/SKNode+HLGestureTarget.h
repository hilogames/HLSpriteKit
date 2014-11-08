//
//  SKNode+HLGestureTarget.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 2/4/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLGestureTarget.h"

@interface SKNode (HLGestureTarget)

/**
 * Returns the gesture target set by hlSetGestureTarget, if any.
 */
- (id <HLGestureTarget>)hlGestureTarget;

/**
 * Attaches a gesture target to this node.  Presumably the gesture delegate (in the main
 * scene or view) will detect when gestures intersect this node, and forward them to this
 * attached gesture target.
 *
 * If the gesture target is the same object as the node, then the pointer to self is not
 * explicitly retained (but will be returned by hlGestureTarget).
 */
- (void)hlSetGestureTarget:(id <HLGestureTarget>)gestureTarget;

@end
