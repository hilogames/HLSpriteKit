//
//  HLScrollNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/20/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLComponentNode.h"
#import "HLGestureTarget.h"

/**
 Specifies a mode for enforcing a scaling minimum (zooming out) for content.
*/
typedef NS_ENUM(NSInteger, HLScrollNodeContentScaleMinimumMode)
{
  /**
   Content scale is allowed as small as the configured `contentScaleMinimum`, but is further
   limited by the `contentSize`: The `HLScrollNode` may only zoom out until one dimension of
   the `contentSize` fits exactly in the inset scroll node area.
  */
  HLScrollNodeContentScaleMinimumFitTight,
  /**
   Content scale is allowed as small as the configured `contentScaleMinimum`, but is
   further limited by the `contentSize`: The `HLScrollNode` may only zoom out until one
   dimension of the `contentSize` fits entirely and the other dimension fits exactly in
   the inset scroll node area.  (In the non-limiting dimension, the content is centered.)
  */
  HLScrollNodeContentScaleMinimumFitLoose,
  /**
   Content scale is allowed as small as the configured `contentScaleMinimum`, regardless
   of the `contentSize` of the `HLScrollNode`.  (Note: Specifying a `contentScaleMinimum`
   of `0.0` in this mode allows zooming out infinitely.)
  */
  HLScrollNodeContentScaleMinimumAsConfigured,
};

/**
 An `HLScrollNode` provides support for scrolling and scaling its content (set via the
 `contentNode` property) with pan and pinch gestures.

 The `HLScrollNode` is not completely analogous to `UIScrollView`, but the similarity is
 deliberate.  One notable difference: The `HLScrollNode` does not currently clip the
 contents to its own size.

 ## Common Gesture Handling Configurations

 - Set this node as its own gesture target (via `[SKNode+HLGestureTarget
   hlSetGestureTarget]`) to get one-finger scrolling and two-finger pinch scaling
   behavior.

 Often the content node will want to handle taps (and the like) while letting pan and
 pinch gestures fall through to the scroll node.  It depends a little on the scene
 implementation, but for `HLScene`, the important part is returning `NO` for `isInside`
 for pan and pinch gesture recognizers in the content node's gesture target implementation
 of `addToGestureRecognizer:firstTouch:isInside:`.  See, for instance, the implementation
 of that method in `HLTapGestureTarget`.
*/
@interface HLScrollNode : HLComponentNode <HLGestureTarget>

/// @name Creating a Scroll Node

/**
 Initializes an `HLScrollNode` with layout-affecting parameters necessary for basic
 scrolling (though not scaling) behavior.

 Set `contentNode` for a functioning `HLScrollNode`.

 Once the `HLScrollNode`'s `contentNode` has been set, changes to the layout-affecting
 parameters might constrain the `HLScrollNode`'s `contentOffset` and `contentScale`
 values.  A simple example:

     HLScrollNode *scrollNode = [[HLScrollNode alloc] init];
     scrollNode.contentNode = myContentNode;
     scrollNode.contentScale = 5.0f;
     scrollNode.contentScaleMaximum = 5.0f;

 The `contentNode` is added with a default `contentScaleMaximum` of `1.0`, which
 constrains the `contentScale` to `1.0` even though it is set to `5.0` and even though the
 maximum is later increased to allow it.  To avoid such complications, one of two
 approaches is recommended: Either set any layout-affecting parameters *before* setting
 the `contentNode`, or else use the other init method (which fully specifies all layout-
 affecting parameters).
*/
- (instancetype)initWithSize:(CGSize)size contentSize:(CGSize)contentSize NS_DESIGNATED_INITIALIZER;

/**
 Initializes an `HLScrollNode` with all layout-affecting parameters.

 Unless the layout-affecting parameters are all fully specified before `contentNode` is
 set, default values can cause the content's offset and scale to be constrained in
 surprising ways.  This method avoids that problem; otherwise, see
 `initWithSize:contentSize:` for notes on the correct way to use that initializer.
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

/// @name Setting Content

/**
 The node that scrolls and scales within the `HLScrollNode`.
*/
@property (nonatomic, strong) SKNode *contentNode;

/// @name Configuring Scroll Node Geometry

/**
 The size of the scroll node in which the content appears.

 Currently, the content is not clipped to this area, but the `contentOffset` and
 `contentScale` are constrained to respect it.
 */
@property (nonatomic, assign) CGSize size;

/**
 The anchor point for the position of the `HLScrollNode` within its parent.
 Default value `(0.5, 0.5)`.
*/
@property (nonatomic, assign) CGPoint anchorPoint;

/// @name Configuring Content Geometry

/**
 The size of the content.

 If the content node has its own `size` property, it will be ignored.  In most cases the
 `contentSize` will be set to the content node's `size`, but it may also be set larger or
 smaller to add or take away margins (that scale with content scale, unlike
 `contentInset`); the exact effect will depend on the value of `contentScaleMinimumMode`
 and `contentAnchorPoint`.
*/
@property (nonatomic, assign) CGSize contentSize;

/**
 The anchor point to be used for the content.

 Default value `(0.5, 0.5)`.

 If the content node has its own `anchorPoint` property, they will be combined.  In most
 cases the `contentAnchorPoint` should be set to the `anchorPoint` of the content node.
*/
@property (nonatomic, assign) CGPoint contentAnchorPoint;

/**
 The distance that the content is inset from the enclosing `HLScrollNode`.

 Default value `UIEdgeInsetsZero`.
*/
@property (nonatomic, assign) UIEdgeInsets contentInset;

/**
 The configured minimum value for content scale (when zooming out).

 See `contentScaleMinimumMode` for scale minimum calculation.  Default value `1.0`.
*/
@property (nonatomic, assign) CGFloat contentScaleMinimum;

/**
 The mode for calculating scale minimum given the configured `contentScaleMinimum`.

 See `HLScrollNodeScaleMinimumMode`.  Default value
 `HLScrollNodeContentMinimumScaleModeFitTight`.
*/
@property (nonatomic, assign) HLScrollNodeContentScaleMinimumMode contentScaleMinimumMode;

/**
 The maximum value for content scale (when zooming in).

 Default value `1.0`.
*/
@property (nonatomic, assign) CGFloat contentScaleMaximum;

/// @name Setting Content Offset and Scale

/**
 The offset of the content's origin from the `HLScrollNode`'s origin.

 Default value `(0.0, 0.0)`.  See methods for other ways of setting `contentOffset`.
*/
@property (nonatomic, assign) CGPoint contentOffset;

/**
 The scale of the content inside the `HLScrollNode`.

 Default value `1.0`.  See methods for other ways of setting `contentScale`.
*/
@property (nonatomic, assign) CGFloat contentScale;

/**
 Set `contentOffset` and contentScale at the same time.

 Since the offset is sometimes constrained by the current scale, it makes sense to set
 them together if both are going to change.
*/
- (void)setContentOffset:(CGPoint)contentOffset contentScale:(CGFloat)contentScale;

/**
 Returns an action that will animate a change to the content offset.

 Returns `nil` if the content node is not set.
*/
- (SKAction *)actionForSetContentOffset:(CGPoint)contentOffset animatedDuration:(NSTimeInterval)duration;

/**
 Convenience method that gets and then runs the action returned by
 `actionForSetContentOffset:animatedDuration:`.

 The timing mode used is `SKActionTimingEaseInEaseOut`.
*/
- (void)setContentOffset:(CGPoint)contentOffset animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

/**
 Returns an action that will animate a change to the content scale.

 Returns `nil` if the content node is not set.
*/
- (SKAction *)actionForSetContentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration;

/**
 Convenience method that gets and then runs the action returned by
 `actionForSetContentScale:animatedDuration:`.

 The timing mode used is `SKActionTimingEaseInEaseOut`.
*/
- (void)setContentScale:(CGFloat)scale animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

/**
 Returns an action that will animate a change of content offset and scale.

 Returns `nil` if the content node is not set.
*/
- (SKAction *)actionForSetContentOffset:(CGPoint)contentOffset contentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration;

/**
 Convenience method that gets and then runs the action returned by
 `actionForSetContentOffset:contentScale:animatedDuration:`.

 The timing mode used is `SKActionTimingEaseInEaseOut`.
*/
- (void)setContentOffset:(CGPoint)contentOffset contentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

/**
 Set `contentOffset` using a location in the content coordinate system (rather than the
 offset, which is always an offset in the `HLScrollNode`'s coordinate system).
*/
- (void)scrollContentLocation:(CGPoint)contentLocation toNodeLocation:(CGPoint)nodeLocation;

/**
 Returns an action that will animate a change of content offset using a location in the
 content coordinate system.
*/
- (SKAction *)actionForScrollContentLocation:(CGPoint)contentLocation toNodeLocation:(CGPoint)nodeLocation animatedDuration:(NSTimeInterval)duration;

/**
 Convenience method that gets and then runs the action returned by
 `actionForScrollContentLocation:toNodeLocation:animatedDuration:`.
*/
- (void)scrollContentLocation:(CGPoint)contentLocation toNodeLocation:(CGPoint)nodeLocation animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

/**
 Set `contentOffset` using a location in the content coordinate system (rather than the
 offset, which is always an offset in the `HLScrollNode`'s coordinate system), and set
 `contentScale` at the same time.
*/
- (void)scrollContentLocation:(CGPoint)contentLocation toNodeLocation:(CGPoint)nodeLocation andSetContentScale:(CGFloat)contentScale;

/**
 Returns an action that will animate a change of content offset using a location in the
 content coordinate system, and a change of content scale at the same time.
*/
- (SKAction *)actionForScrollContentLocation:(CGPoint)contentLocation toNodeLocation:(CGPoint)nodeLocation andSetContentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration;

/**
 Convenience method that gets and then runs the action returned by
 `actionForScrollContentLocation:toNodeLocation:andSetContentScale:animatedDuration:`.
*/
- (void)scrollContentLocation:(CGPoint)contentLocation toNodeLocation:(CGPoint)nodeLocation andSetContentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

/**
 Change `contentScale` while pinning a certain location in the content coordinate system
 to a location in the node's coordinate system.
*/
- (void)pinContentLocation:(CGPoint)contentLocation andSetContentScale:(CGFloat)contentScale;

/**
 Returns an cation that will animate a change of `contentScale` while pinning a certain
 location in the content coordinate system to a location in the node's coordinate system.
*/
- (SKAction *)actionForPinContentLocation:(CGPoint)contentLocation andSetContentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration;

/**
 Convenience method that gets and then runs the action returned by
 `actionForPinContentLocation:andSetContentScale:animatedDuration:`.
*/
- (void)pinContentLocation:(CGPoint)contentLocation andSetContentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

@end
