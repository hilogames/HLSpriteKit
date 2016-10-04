//
//  HLToolbarNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 12/12/13.
//  Copyright (c) 2013 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import <TargetConditionals.h>

#import "HLComponentNode.h"
#import "HLGestureTarget.h"

@protocol HLToolbarNodeDelegate;

/**
 Justification for toolbar tools.
*/
typedef NS_ENUM(NSInteger, HLToolbarNodeJustification) {
  HLToolbarNodeJustificationCenter,
  HLToolbarNodeJustificationLeft,
  HLToolbarNodeJustificationRight
};

/**
 Animation used for setting toolbar tools.

 Some of these animation options will look silly unless property `contentClipped`
 is set to `YES`.  (See the notes at `contentClipped` for an explanation why it
 defaults to `NO`.)
*/
typedef NS_ENUM(NSInteger, HLToolbarNodeAnimation) {
  HLToolbarNodeAnimationNone,
  HLToolbarNodeAnimationSlideUp,
  HLToolbarNodeAnimationSlideDown,
  HLToolbarNodeAnimationSlideLeft,
  HLToolbarNodeAnimationSlideRight
};

/**
 `HLToolbarNode` lays out its content ("tools") in a horizontal row of squares, like a
 toolbar.  It provides various visual formatting options, and also various geometry
 options (for example, fitting the tools to a certain toolbar size).  It maintains some
 state information about tools (like enabled and highlight), and provides some simple
 animation for paging or setting tools in the toolbar.

 ## Common User Interaction Configurations

 As a gesture target:

 - Set this node as its own gesture target (using `[SKNode+HLGestureTarget
   hlSetGestureTarget]`) to get simple delegation and/or a callback for taps or clicks.
   See `HLToolbarNodeDelegate` for delegation and the `toolTappedBlock` or
   `toolClickedBlock` properties for setting a callback block.

 - Set a custom gesture target to recognize and respond to other gestures.  (Convert
   gesture locations to this node's coordinate system and call `toolAtLocation` as
   desired.)

 - Leave the gesture target unset for no gesture handling.

 As a `UIResponder`:

 - Set this node's `userInteractionEnabled` property to true to get simple delegation
   and/or a callback for taps.  See `HLToolbarNodeDelegate` for delegation and
   `toolTappedBlock` property for setting a callback block.

 As an `NSResponder`:

 - Set this node's `userInteractionEnabled` property to true to get simple delegation
   and/or a callback for left-clicks.  See `HLToolbarNodeDelegate` for delegation and
   `toolClickedBlock` property for setting a callback block.
*/
@interface HLToolbarNode : HLComponentNode <NSCoding, HLGestureTarget>

/// @name Creating a Toolbar Node

/**
 Initializes a toolbar node.
*/
- (instancetype)init;

/// @name Setting the Delegate

/**
 The toolbar node delegate.
*/
@property (nonatomic, weak) id <HLToolbarNodeDelegate> delegate;

/// @name Managing Interaction

#if TARGET_OS_IPHONE

/**
 A callback invoked when a tool is tapped.

 The tag of the tapped tool is passed as an argument to the callback.

 Relevant to `HLGestureTarget` and `UIResponder` user interaction.
 See "Common User Interaction Configurations".

 Beware retain cycles when using the callback to invoke a method in the owner.  As a safer
 alternative, use the toolbar node's delegation interface; see `setDelegate:`.
*/
@property (nonatomic, copy) void (^toolTappedBlock)(NSString *toolTag);

#else

/**
 A callback invoked when a tool is clicked.

 The tag of the clicked tool is passed as an argument to the callback.

 Relevant to `NSResponder` user interaction.
 See "Common User Interaction Configurations".

 Beware retain cycles when using the callback to invoke a method in the owner.  As a safer
 alternative, use the toolbar node's delegation interface; see `setDelegate:`.
 */
@property (nonatomic, copy) void (^toolClickedBlock)(NSString *toolTag);

#endif

/// @name Getting and Setting Tools

/**
 Sets tool nodes in the toolbar and effects layout according to all object properties.

 The square node that holds each tool has `anchorPoint` `(0.5, 0.5)`.

 Any `SKNode` descendant may be used as a tool, but any tools which conform to
 `HLItemContentNode` can customize their behavior and/or appearance for certain toolbar
 functions (for example, setting enabled or highlight); see `HLItemContentNode` for
 details.

 Each tool node is expected to have a size selector which reports its desired size.  (The
 size is expected to behave like `[SKSpriteNode size]` property, where the `SKNode`
 `xScale` and `yScale` are already reflected in the reported size, but the `SKNode`
 `zRotation` is not.)  Depending on other object properties, either the tools will be
 scaled to fit the toolbar or vice versa.  In particular:

 - If `automaticWidth` and `automaticHeight` are both `YES`, the toolbar will set its
   height to the maximum tool node height (plus relevant pads and borders) and its width
   to the sum of the tool node widths (plus relevant pads and borders).  (The tools won't
   be scaled; that is, they will remain their natural size.)

 - If only `automaticWidth` is `YES`, and toolbar height is fixed, the toolbar will scale
   the tool nodes so that the tallest tool node will fit the toolbar height (plus relevant
   pads and borders), and the others will be scaled proportionally.  If
   `automaticToolsScaleLimit` is `YES`, then the scaling of the tools will not exceed
   their natural size.

 - If only `automaticHeight` is `YES`, and toolbar width is fixed, the toolbar will scale
   the tool nodes proportionally to each other so that the sum of tool node widths will
   fit the toolbar width (plus relevant pads and borders).  If `automaticToolsScaleLimit`
   is `YES`, then the scaling of the tools will not exceed their natural size.

 - Otherwise, with both toolbar width and height fixed, the toolbar will scale the tools
   proportionally so they fit into both the fixed width and fixed height.  If
   `automaticToolsScaleLimit` is `YES`, then the scaling of the tools will not exceed
   their natural size.

 @param toolNodes The array of `SKNode`s to be set as tools.

 @param toolTags An array of same length as tools containing strings to be used as
                 identifiers for the tools.  These tags (rather than, for example, indexes
                 in the array) are used in all other interfaces in this object interacting
                 with particular tools.

 @param animation Animation, if any.  See `HLToolbarNodeAnimation`.
*/
- (void)setTools:(NSArray *)toolNodes tags:(NSArray *)toolTags animation:(HLToolbarNodeAnimation)animation;

/**
 Replaces an already-set tool node in the toolbar with a new tool node.

 Preserves the old tool's tag and state (enabled and highlight).

 Does not automatically recalculate layout; if the layout is changed (for instance, if the
 new tool node is a different size than the old one in a way that matters), then the owner
 should call `layoutToolsAnimation:`.
*/
- (void)setTool:(SKNode *)toolNode forTag:(NSString *)toolTag;

/**
 Returns the tag of the tool at the passed location, or `nil` for none.

 The location is expected to be in the coordinate system of this node.
*/
- (NSString *)toolAtLocation:(CGPoint)location;

/**
 Returns the square node that contains the tool node corresponding to the passed tag,
 or `nil` for none.

 Modification of the square node is neither expected nor recommended.
*/
- (SKNode *)squareNodeForTool:(NSString *)toolTag;

/**
 The number of tools last set by `setTools:tags:animation:`.

 Provided as a convenience for the caller.
*/
- (NSUInteger)toolCount;

/// @name Configuring Toolbar Appearance

/**
 Main toolbar color, showing as background behind tool squares.

 Default is `[SKColor colorWithWhite:0.0 alpha:0.5]`.
*/
@property (nonatomic, strong) SKColor *backgroundColor;

/**
 Tool square color, showing behind each tool node set.

 Default is `[SKColor colorWithWhite:0.7 alpha:0.5]`.
*/
@property (nonatomic, strong) SKColor *squareColor;

/**
 Tool square color when highlighted.

 Default is `[SKColor colorWithWhite:1.0 alpha:0.8]`.
*/
@property (nonatomic, strong) SKColor *highlightColor;

/**
 Alpha value for tool square (and inherited by tool node in square) when tool is enabled.

 Default is `1.0`.
*/
@property (nonatomic, assign) CGFloat enabledAlpha;

/**
 Alpha value for tool square (and inherited by tool node in square) when tool is
 disabled.

 Default is `0.4`.
*/
@property (nonatomic, assign) CGFloat disabledAlpha;

/// @name Configuring Toolbar Geometry

/**
 Effects layout according to all object properties.

 See `setTools:tags:animation:` for details.

 In general, this method (or `setTools:tags:animation:`) must be called after modifying
 any geometry-related (layout-affecting) object property.  Requiring an explicit call
 allows the caller to set multiple properties at the same time efficiently.
*/
- (void)layoutToolsAnimation:(HLToolbarNodeAnimation)animation;

/**
 Whether or not the content is clipped (cropped) to the overall toolbar dimensions.

 Default value is `NO`.

 This is especially relevant to the animation options offered by `HLToolbarNodeAnimation`
 while setting tools in the toolbar node: Some animation options will look silly without
 clipping.  And in fact, this option would default `YES`, or would not even be offered
 as an option, except that sometimes the owner needs to control whether or not the
 hierarchy includes an `SKCropNode`; see the bug below.

 @bug When a descendant node of the `contentNode` is an `SKCropNode`, the clipping of
      contents is irregular, affecting some descendants but not others.  Unfortunately
      it can be difficult to determine the culprit, since crop nodes are sometimes
      hidden in the implementation of custom nodes.  Also: In certain versions of iOS,
      adding an SKEffectNode as a descendant of an SKCropNode causes the effect to render
      incorrectly.
 */
@property (nonatomic, assign, getter=isContentClipped) BOOL contentClipped;

/**
 Whether the toolbar should automatically size its width according to its tools.

 Default value is `NO`.

 See `setTools:tags:animation:` for details.

 Changes will not take effect until the next call to `layoutToolsAnimation:` or
 `setTools:tags:animation:`.
*/
@property (nonatomic, assign) BOOL automaticWidth;

/**
 Whether the toolbar should automatically size its height according to its tools.

 Default value is `NO`.

 See `setTools:tags:animation:` for details.

 Changes will not take effect until the next call to `layoutToolsAnimation:` or
 `setTools:tags:animation:`.
*/
@property (nonatomic, assign) BOOL automaticHeight;

/**
 Whether the tools should be allowed to scale larger than their natural size during
 automatic sizing.

 Default value is `NO`.

 See `setTools:tags:animation:` for details.

 Changes will not take effect until the next call to `layoutToolsAnimation:` or
 `setTools:tags:animation:`.
*/
@property (nonatomic, assign) BOOL automaticToolsScaleLimit;

/**
 Overall toolbar size.

 Changes will not take effect until the next call to `layoutToolsAnimation:` or
 `setTools:tags:animation:`.

 After layout, this property will be set to the actual size of the toolbar.  In
 particular, a caller-provided width or height will probably be changed during
 layout if `automaticWidth` or `automaticHeight` (respectively) is set to YES.
*/
@property (nonatomic, assign) CGSize size;

/**
 The anchor point used by the toolbar.

 Default value is `(0.5, 0.5)`.

 Changes will not take effect until the next call to `layoutToolsAnimation:` or
 `setTools:tags:animation:`.
*/
@property (nonatomic, assign) CGPoint anchorPoint;

/**
 The justification of tools within the toolbar.

 Default value is `HLToolbarNodeJustificationCenter`.  See `HLToolbarNodeJustification`.

 Changes will not take effect until the next call to `layoutToolsAnimation:` or
 `setTools:tags:animation:`.
*/
@property (nonatomic, assign) HLToolbarNodeJustification justification;

/**
 The amount of toolbar background that shows as a border around the outside tool
 squares.

 Default value is `4.0`.

 Changes will not take effect until the next call to `layoutToolsAnimation:` or
 `setTools:tags:animation:`.
*/
@property (nonatomic, assign) CGFloat backgroundBorderSize;

/**
 The amount of toolbar background that shows between each tool square on the toolbar.

 Default value is `4.0`.

 Changes will not take effect until the next call to `layoutToolsAnimation:` or
 `setTools:tags:animation:`.
*/
@property (nonatomic, assign) CGFloat squareSeparatorSize;

/**
 The extra space added between the edge of the tool square (made for each tool) and the
 user-supplied tool node itself.

 Default value is `0.0`.

 Negative values mean the tool square will be drawn smaller than the tool node.

 Changes will not take effect until the next call to `layoutToolsAnimation:` or
 `setTools:tags:animation:`.
*/
@property (nonatomic, assign) CGFloat toolPad;

/// @name Managing Tool State

/**
 Returns a boolean indicating the current highlight state of a tool.
*/
- (BOOL)highlightForTool:(NSString *)toolTag;

/**
 Sets the highlight state of a tool.

 If the tool node conforms to `HLItemContentNode` implementing
 `hlItemContentSetHighlight`, then that method will be called.  Otherwise, the color of
 the square will be set either to `highlightColor` or `squareColor`.
*/
- (void)setHighlight:(BOOL)highlight forTool:(NSString *)toolTag;

/**
 Convenience method for toggling the current highlight state of a tool.
*/
- (void)toggleHighlightForTool:(NSString *)toolTag;

/**
 Sets the highlight state of a tool with animation.

 If the tool node conforms to `HLItemContentNode` implementing
 `hlItemContentSetHighlight`, then that method will be called.  Otherwise, the color of
 the tool will be set either to `highlightColor` or `squareColor`.

 @param finalHighlight The intended highlight value for the tool when the animation is
                       complete.

 @param toolTag The tag of the tool being animated.

 @param blinkCount The number of times the highlight value will cycle from its current
                   value to the final value.

 @param halfCycleDuration The amount of time it takes to cycle the highlight during a
                          blink; a full blink will be completed in twice this duration.

 @param completion A block that will be run when the animation is complete.
*/
- (void)setHighlight:(BOOL)finalHighlight forTool:(NSString *)toolTag
          blinkCount:(int)blinkCount
   halfCycleDuration:(NSTimeInterval)halfCycleDuration
          completion:(void(^)(void))completion;

/**
 Returns a boolean indicating the current enabled state of a tool.
*/
- (BOOL)enabledForTool:(NSString *)toolTag;

/**
 Sets the enabled state of a tool.

 If the tool node conforms to `HLItemContentNode` implementing `hlItemContentSetEnabled`,
 then that method will be called.  Otherwise, the alpha value of the square will be set
 either to `enabledAlpha` or `disabledAlpha`.
*/
- (void)setEnabled:(BOOL)enabled forTool:(NSString *)toolTag;

@end

/**
 A delegate for `HLToolbarNode`.
*/
@protocol HLToolbarNodeDelegate <NSObject>

/// @name Handling User Interaction

#if TARGET_OS_IPHONE

/**
 Called when the user taps a tool.

 Relevant to `HLGestureTarget` and `UIResponder` user interaction.
 See "Common User Interaction Configurations".
*/
- (void)toolbarNode:(HLToolbarNode *)toolbarNode didTapTool:(NSString *)toolTag;

#else

/**
 Called when the user clicks a tool.

 Relevant to `NSResponder` user interaction.
 See "Common User Interaction Configurations".
 */
- (void)toolbarNode:(HLToolbarNode *)toolbarNode didClickTool:(NSString *)toolTag;

#endif

@end

#if TARGET_OS_IPHONE

@protocol HLToolbarNodeMultiGestureTargetDelegate;

/**
 A gesture target for toolbar nodes that handles taps, double-taps, long-presses, and
 pans.
*/
@interface HLToolbarNodeMultiGestureTarget : NSObject <HLGestureTarget>

/**
 Initializes a new multi-gesture target for a particular toolbar node.
*/
- (instancetype)initWithToolbarNode:(HLToolbarNode *)toolbarNode;

/**
 The toolbar node for which this target handles gestures.
*/
@property (nonatomic, weak) HLToolbarNode *toolbarNode;

/**
 The delegate invoked when the target handles gestures.
*/
@property (nonatomic, weak) id <HLToolbarNodeMultiGestureTargetDelegate> delegate;

@end

@protocol HLToolbarNodeMultiGestureTargetDelegate <NSObject>

/**
 Invoked when the multi-gesture target handles a tap on a tool.
*/
- (void)toolbarNode:(HLToolbarNode *)toolbarNode didTapTool:(NSString *)toolTag;

/**
 Invoked when the multi-gesture target handles a double-tap on a tool.
*/
- (void)toolbarNode:(HLToolbarNode *)toolbarNode didDoubleTapTool:(NSString *)toolTag;

/**
 Invoked when the multi-gesture target handles a long press on a tool.
*/
- (void)toolbarNode:(HLToolbarNode *)toolbarNode didLongPressTool:(NSString *)toolTag;

/**
 Invoked when the multi-gesture target handles a pan on a tool.
*/
- (void)toolbarNode:(HLToolbarNode *)toolbarNode didPanWithGestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer;

@end

#endif
