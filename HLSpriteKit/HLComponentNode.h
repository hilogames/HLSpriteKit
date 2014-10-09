//
//  HLComponentNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/6/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLGestureTarget.h"

@interface HLComponentNode : SKNode <NSCoding, NSCopying, HLGestureTarget>

/**
 * The HLGestureTarget interface is fairly lightweight, so all HLComponents are provided with
 * an implementation of it, even if they don't seem particularly gesture-targety (e.g. HLTiledNode).
 * See notes in HLComponent subclass header files on common gesture target configurations for
 * the particular component.
 */
- (void)setGestureTargetDelegateWeak:(id<HLGestureTargetDelegate>)delegate;
- (void)setGestureTargetDelegateStrong:(id<HLGestureTargetDelegate>)delegate;
- (id<HLGestureTargetDelegate>)gestureTargetDelegate;

/**
 * By default, because of SKScene's ignoresSiblingOrder property, scenes use node tree structure
 * to determine rendering order of child nodes.  When ignoresSiblingOrder is set to YES, though
 * there is a potential for difficulty:
 *
 *   . On one hand, a scene must remain in complete control of the zPositions of its components,
 *     so that it can determine render order.  For instance, if two components A and B are siblings
 *     in the scene, the scene might choose to render B above A by setting A.zPosition to 0.0f and
 *     B.zPosition to 1.0f.  Component A must not then have a child node which has its own zPosition
 *     of 10.0f relative to its root node A.
 *
 *   . On the other hand, the child nodes of a component (i.e. a custom subclass of SKNode), by
 *     convention, are considered private, and should only be managed by the component.
 *
 * The zPositionScale provides a way for the scene to limit the range or scale of zPositions used
 * by any children nodes of the component.  To continue the previous example, the scene might control
 * rendering order like this:
 *
 *     a.zPosition = 0.0f;
 *     a.zPositionScale = 1.0f;
 *
 *     b.zPosition = 1.0f;
 *     b.zPositionScale = 1.0f;
 *
 * Component A will limit itself to the zPositions from [0.0f,1.0f).  The principle continues to apply
 * when components contain components, of course; a menu component containing button components will
 * decide how many layers it needs, divide its own zPositionScale into smaller scales for each layer,
 * and set each owned component with the smaller scale value.
 *
 * It's worth emphasizing: The component shall keep all of its child node zPositions *less* than the
 * largest value in the scale.  For instance, if a component has a scale of 3.0f and it needs three
 * layers, it is conventional that it should calculate for its layers zPositions of 0.0f, 1.0f, and
 * 2.0f (and not use 3.0f or even 2.99999999f).
 *
 * Default value is 1.0f.
 */
@property (nonatomic, assign) CGFloat zPositionScale;

@end
