//
//  HLScrollNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/20/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLComponentNode.h"

/**
 * Specifies a mode for enforcing a scaling minimum (zooming out) for content.  Current
 * options:
 *
 *  . HLScrollNodeContentScaleMinimumFitTight: Content scale is allowed as small as
 *    the configured contentScaleMinimum, but is further limited by the contentSize:
 *    The HLScrollNode may only zoom out until one dimension of the contentSize fits
 *    exactly in the inset scroll node area.
 *
 *  . HLScrollNodeContentScaleMinimumFitLoose: Content scale is allowed as small as
 *    the configured contentScaleMinimum, but is further limited by the contentSize:
 *    The HLScrollNode may only zoom out until one dimension of the contentSize fits
 *    entirely and the other dimension fits exactly in the inset scroll node area.
 *    (In the non-limiting dimension, the content is centered.)
 *
 *  . HLScrollNodeContentScaleMinimumAsConfigured: Content scale is allowed as small as
 *    the configured contentScaleMinimum, regardless of the contentSize of the
 *    HLScrollNode.  (Note: Specifying a contentScaleMinimum of 0.0f in this mode
 *    allows zooming out infinitely.)
 */
typedef NS_ENUM(NSInteger, HLScrollNodeContentScaleMinimumMode)
{
  HLScrollNodeContentScaleMinimumFitTight,
  HLScrollNodeContentScaleMinimumFitLoose,
  HLScrollNodeContentScaleMinimumAsConfigured,
};

/**
 * An HLScrollNode provides support for scrolling and scaling its content (set
 * via the contentNode property) with pan and pinch gestures.
 *
 * note: The HLScrollNode is not completely analogous to the UIScrollView, but
 * the similarity is deliberate.  One notable difference: The HLScrollNode does
 * not currently clip the contents to its own size.
 */
@interface HLScrollNode : HLComponentNode <HLGestureTarget, HLGestureTargetDelegate>

/**
 * Common gesture handling configurations:
 *
 *   - Set the gesture target delegate to the gesture target (this HLScrollNode)
 *     to get one-finger scrolling and two-finger pinch scaling behavior.  (Set
 *     the delegate weakly to avoid retain cycles.)
 */

@property (nonatomic, assign) CGSize size;

/**
 * The anchor point for the position of the HLScrollNode within its parent.
 * Default value (0.5,0.5).
 */
@property (nonatomic, assign) CGPoint anchorPoint;

@property (nonatomic, strong) SKNode *contentNode;

/**
 * The size of the content.
 *
 * If the content node has its own size property, it will be ignored.  In most
 * cases the contentSize will be set to the content node's size, but it may
 * also be set larger or smaller to add or take away margins (that scale with
 * content scale, unlike contentInset); the exact effect will depend on the value
 * of contentScaleMinimumMode and contentAnchorPoint.
 */
@property (nonatomic, assign) CGSize contentSize;

/**
 * The anchor point to be used for the content.  Default value (0.5,0.5).
 *
 * If the content node has its own anchorPoint property, they will be combined.
 * In most cases the contentAnchorPoint should be set to the anchorPoint of the
 * content node.
 */
@property (nonatomic, assign) CGPoint contentAnchorPoint;

/**
 * The offset of the content's origin from the HLScrollNode's origin.  Default
 * value (0.0,0.0).  See methods for other ways of setting contentOffset.
 */
@property (nonatomic, assign) CGPoint contentOffset;

/**
 * The distance that the content is inset from the enclosing HLScrollNode.
 * Default value UIEdgeInsetsZero.
 */
@property (nonatomic, assign) UIEdgeInsets contentInset;

/**
 * The scale of the content inside the HLScrollNode.  Scale changes can be
 * animated using setContentScale:animatedDuration:completion:.  Default
 * value 1.0.  See methods for other ways of setting contentScale.
 */
@property (nonatomic, assign) CGFloat contentScale;

/**
 * The configured minimum value for content scale (when zooming out).  See
 * contentScaleMinimumMode for scale minimum calculation.  Default value 1.0.
 */
@property (nonatomic, assign) CGFloat contentScaleMinimum;

/**
 * The mode for calculating scale minimum given the configured contentScaleMinimum.
 * See HLScrollNodeScaleMinimumMode.  Default value HLScrollNodeContentMinimumScaleModeFitTight.
 */
@property (nonatomic, assign) HLScrollNodeContentScaleMinimumMode contentScaleMinimumMode;

/**
 * The maximum value for content scale (when zooming in).  Default value 1.0.
 */
@property (nonatomic, assign) CGFloat contentScaleMaximum;

/**
 * Initializes an HLScrollNode with layout-affecting parameters necessary for basic
 * scrolling (though not scaling) behavior.  Set contentNode for a functioning HLScrollNode.
 *
 * Once the HLScrollNode's contentNode has been set, changes to the layout-affecting
 * parameters might constrain the HLScrollNode's contentOffset and contentScale values.
 * A simple example:
 *
 *   HLScrollNode *scrollNode = [[HLScrollNode alloc] init];
 *   scrollNode.contentNode = myContentNode;
 *   scrollNode.contentScale = 5.0f;
 *   scrollNode.contentScaleMaximum = 5.0f;
 *
 * The contentNode is added with a default contentScaleMaximum of 1.0f, which constrains
 * the contentScale to 1.0f even though it is set to 5.0f and even though the maximum
 * is later increased to allow it.  To avoid such complications, one of two approaches
 * is recommended: Either set any layout-affecting parameters *before* setting the
 * contentNode, or else use the other init method (which fully specifies all layout-
 * affecting parameters).
 */
- (instancetype)initWithSize:(CGSize)size contentSize:(CGSize)contentSize NS_DESIGNATED_INITIALIZER;

/**
 * Initializes an HLScrollNode with all layout-affecting parameters.
 *
 * note: Unless the layout-affecting parameters are all fully specified before contentNode,
 * is set, default values can cause the content's offset and scale to be constrained in
 * surprising ways.  This init method avoids that problem; see initWithSize:contentSize: for
 * notes on the correct way to use that initializer.
 */
- (instancetype)initWithSize:(CGSize)size
                 anchorPoint:(CGPoint)anchorPoint
                     content:(SKNode *)contentNode
                 contentSize:(CGSize)contentSize
          contentAnchorPoint:(CGPoint)contentAnchorPoint
               contentOffset:(CGPoint)contentOffset
                contentInset:(UIEdgeInsets)contentInset
                contentScale:(CGFloat)contentScale
         contentScaleMinimum:(CGFloat)contentScaleMinimum
     contentScaleMinimumMode:(HLScrollNodeContentScaleMinimumMode)contentScaleMinimumMode
         contentScaleMaximum:(CGFloat)contentScaleMaximum NS_DESIGNATED_INITIALIZER;

/**
 * Returns an action that will animate a change to the content offset.  Returns nil
 * if the content node is not set.
 */
- (SKAction *)actionForSetContentOffset:(CGPoint)contentOffset animatedDuration:(NSTimeInterval)duration;

/**
 * Convenience method that gets and then runs the action returned by
 * actionForSetContentOffset:animatedDuration:.  The timing mode used is
 * SKActionTimingEaseInEaseOut.
 */
- (void)setContentOffset:(CGPoint)contentOffset animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

/**
 * Returns an action that will animate a change to the content scale.  Returns nil
 * if the content node is not set.
 */
- (SKAction *)actionForSetContentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration;

/**
 * Convenience method that gets and then runs the action returned by
 * actionForSetContentScale:animatedDuration:.  The timing mode used is
 * SKActionTimingEaseInEaseOut.
 */
- (void)setContentScale:(CGFloat)scale animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

/**
 * Set contentOffset and contentScale at the same time.  Since the offset is sometimes
 * constrained by the current scale, it makes sense to set them together if both are
 * going to change.
 */
- (void)setContentOffset:(CGPoint)contentOffset contentScale:(CGFloat)contentScale;

/**
 * Returns an action that will animate a change of content offset and scale.  Returns nil
 * if the content node is not set.
 */
- (SKAction *)actionForSetContentOffset:(CGPoint)contentOffset contentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration;

/**
 * Convenience method that gets and then runs the action returned by
 * actionForSetContentOffset:contentScale:animatedDuration:.  The timing mode used is
 * SKActionTimingEaseInEaseOut.
 */
- (void)setContentOffset:(CGPoint)contentOffset contentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

/**
 * Set contentOffset and/or contentScale using locations in the content coordinate
 * system (rather than the offset, which is always an offset in the HLScrollNode's
 * coordinate system).
 *
 * For the most part, these could be implemented as convenience helper methods in the
 * class namespace (i.e. using only the public interface of the HLScrollNode), but
 * there are a few shortcuts and cheats possible when implementing them privately.
 */

- (void)scrollContentLocation:(CGPoint)contentLocation toNodeLocation:(CGPoint)nodeLocation;

- (SKAction *)actionForScrollContentLocation:(CGPoint)contentLocation toNodeLocation:(CGPoint)nodeLocation animatedDuration:(NSTimeInterval)duration;

- (void)scrollContentLocation:(CGPoint)contentLocation toNodeLocation:(CGPoint)nodeLocation animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

- (void)scrollContentLocation:(CGPoint)contentLocation toNodeLocation:(CGPoint)nodeLocation andSetContentScale:(CGFloat)contentScale;

- (SKAction *)actionForScrollContentLocation:(CGPoint)contentLocation toNodeLocation:(CGPoint)nodeLocation andSetContentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration;

- (void)scrollContentLocation:(CGPoint)contentLocation toNodeLocation:(CGPoint)nodeLocation andSetContentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

- (void)pinContentLocation:(CGPoint)contentLocation andSetContentScale:(CGFloat)contentScale;

- (SKAction *)actionForPinContentLocation:(CGPoint)contentLocation andSetContentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration;

- (void)pinContentLocation:(CGPoint)contentLocation andSetContentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

@end
