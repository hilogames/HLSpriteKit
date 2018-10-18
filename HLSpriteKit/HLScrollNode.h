//
//  HLScrollNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/20/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <TargetConditionals.h>

#import "HLComponentNode.h"
#import "HLGestureTarget.h"

@protocol HLScrollNodeDelegate;

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
 An `HLScrollNode` provides support for scrolling and zooming its content (set by the
 `contentNode` property).

 The `HLScrollNode` is not completely analogous to `UIScrollView`, but the similarity is
 deliberate.  One notable difference: The `HLScrollNode` does not currently clip the
 contents to its own size except when configured to do so using the `contentClipped`
 property.

 ## Common User Interaction Configurations

 As a gesture target:

 - Set this node as its own gesture target (using `[SKNode+HLGestureTarget
   hlSetGestureTarget]`) to get scrolling on pan (under iOS) or left-click (under macOS),
   and zooming on pinch (under iOS and macOS trackpad).  (Mouse scroll wheel would be good
   for zooming under macOS, but scroll wheel events are not forwarded to the scene by
   `SKView`.)

 Often the content node will want to handle taps (and the like) while letting pan and
 pinch gestures fall through to the scroll node.  It depends a little on the scene
 implementation, but for `HLScene`, the important part is returning `NO` for `isInside`
 for pan and pinch gesture recognizers in the content node's gesture target implementation
 of `addToGestureRecognizer:firstTouch:isInside:`.  See, for instance, the implementation
 of that method in `HLTapGestureTarget`.

 As a `UIResponder`:

 - Set this node's `userInteractionEnabled` property to true to get one-finger scrolling
   and two-finger pinch zooming behavior.  (The `SKView` must have `multipleTouchEnabled`
   in order to forward two-finger gestures to nodes.)

 As an `NSResponder`:

 - Set this node's `userInteractionEnabled` property to true to get scrolling on left mouse
   button drag.  (Mouse scroll wheel would be a good candidate for zooming interaction, but
   scroll wheel events are not forwarded to the scene by `SKView`.)
*/
@interface HLScrollNode : HLComponentNode <NSCoding, HLGestureTarget>

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
- (instancetype)initWithSize:(CGSize)size contentSize:(CGSize)contentSize;

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
#if TARGET_OS_IPHONE
                contentInset:(UIEdgeInsets)contentInset
#else
                contentInset:(NSEdgeInsets)contentInset
#endif
                contentScale:(CGFloat)contentScale
         contentScaleMinimum:(CGFloat)contentScaleMinimum
     contentScaleMinimumMode:(HLScrollNodeContentScaleMinimumMode)contentScaleMinimumMode
         contentScaleMaximum:(CGFloat)contentScaleMaximum;

/// @name Setting the Delegate

/**
 The scroll node delegate.
*/
@property (nonatomic, weak) id <HLScrollNodeDelegate> delegate;

/// @name Setting Content

/**
 The node that scrolls and scales within the `HLScrollNode`.

 For efficiency (to minimize unnecessary layouts), set all layout-affecting parameters
 before setting `contentNode`.
*/
@property (nonatomic, strong) SKNode *contentNode;

/**
 Set content node and various content properties at the same time.

 This is partly a convenience method, but more importantly it suggests the most efficient
 way to accomplish the task.  Setting the properties individually, otherwise, might result
 in superfluous layout calls (internally).

 The properties accepted by the method are not **all** the possible layout-affecting
 parameters; see the big long init method for notes.  However, these are the deemed
 the most common layout-affecting parameters that might change if a scroll node's
 content node is changed.

 For an efficient way to set an arbitrary number of layout-affecting parameters, follow
 this pattern: If `contentNode` is unset, then content properties may be set without any
 internal layout attempted.  For instance:

     scrollNode.contentNode = nil;
     scrollNode.contentSize = newContentSize;
     scrollNode.contentOffset = CGPointZero;
     scrollNode.contentAnchorPoint = newContentAnchorPoint;
     scrollNode.contentNode = newContentNode;
*/
- (void)setContent:(SKNode *)contentNode
       contentSize:(CGSize)contentSize
     contentOffset:(CGPoint)contentOffset
      contentScale:(CGFloat)contentScale;

/// @name Configuring Scroll Node Geometry

/**
 The size of the scroll node in which the content appears.

 The `contentOffset` and `contentScale` are constrained to respect this size.  If
 `contentClipped` is `YES`, the content will be cropped to this size.
*/
@property (nonatomic, assign) CGSize size;

/**
 The anchor point for the position of the `HLScrollNode` within its parent.  Default value
 `(0.5, 0.5)`.
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
#if TARGET_OS_IPHONE
@property (nonatomic, assign) UIEdgeInsets contentInset;
#else
@property (nonatomic, assign) NSEdgeInsets contentInset;
#endif

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

/**
 Whether or not the content is clipped (cropped) to the overall scroll node dimensions.

 Default value is `NO`.

 @bug When a descendant node of the `contentNode` is an `SKCropNode`, the clipping of
      contents is irregular, affecting some descendants but not others.  Unfortunately
      it can be difficult to determine the culprit, since crop nodes are sometimes
      hidden in the implementation of custom nodes.  Also: In certain versions of iOS,
      adding an SKEffectNode as a descendant of an SKCropNode causes the effect to render
      incorrectly.
*/
@property (nonatomic, assign, getter=isContentClipped) BOOL contentClipped;

/// @name Configuring Scrolling Behavior

/**
 The rate at which the scroll view decelerates after the user ends interaction.

 Default value is `0.998`, which corresponds to `UIScrollViewDecelerationRateNormal`.
 Fast deceleration is `0.990`, which corresponds to `UIScrollViewDecelerationRateFast`.
 Instant deceleration is `0.0`.
*/
@property (nonatomic, assign) CGFloat decelerationRate;

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
 Sets `contentOffset` and contentScale at the same time.

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
 Sets `contentOffset` using a location in the content coordinate system (rather than the
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
 Sets `contentOffset` using a location in the content coordinate system (rather than the
 offset, which is always an offset in the `HLScrollNode`'s coordinate system), and sets
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
 Changes `contentScale` while pinning a certain location in the content coordinate system
 to a location in the node's coordinate system.
*/
- (void)pinContentLocation:(CGPoint)contentLocation andSetContentScale:(CGFloat)contentScale;

/**
 Returns an action that will animate a change of `contentScale` while pinning a certain
 location in the content coordinate system to a location in the node's coordinate system.
*/
- (SKAction *)actionForPinContentLocation:(CGPoint)contentLocation andSetContentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration;

/**
 Convenience method that gets and then runs the action returned by
 `actionForPinContentLocation:andSetContentScale:animatedDuration:`.
*/
- (void)pinContentLocation:(CGPoint)contentLocation andSetContentScale:(CGFloat)contentScale animatedDuration:(NSTimeInterval)duration completion:(void (^)(void))completion;

@end

/**
 A delegate for `HLScrollNode`.
*/
@protocol HLScrollNodeDelegate <NSObject>

/// @name Handling User Interaction

/**
 Called when the user scrolls the scroll node.

 Not called when the scroll is triggered programmatically (rather than by interaction).

 Relevant to `HLGestureTarget` and `NSResponder` user interaction.
 See "Common User Interaction Configurations".
*/
@optional
- (void)scrollNode:(HLScrollNode *)scrollNode didScrollToContentOffset:(CGPoint)contentOffset;

/**
 Called when the user zooms the scroll node.

 Not called when the zoom is triggered programmatically (rather than by interaction).

 Relevant to `HLGestureTarget` and `NSResponder` user interaction.
 See "Common User Interaction Configurations".
*/
@optional
- (void)scrollNode:(HLScrollNode *)scrollNode didZoomToContentScale:(CGFloat)contentScale;

@end
