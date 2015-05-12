//
//  HLToolbarNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 12/12/13.
//  Copyright (c) 2013 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

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

 ## Common Gesture Handling Configurations

 - Set this node as its own gesture target (using `[SKNode+HLGestureTarget
   hlSetGestureTarget]`) to get a simple delegation and/or callback for taps.  See
   `HLToolbarNodeDelegate` for delegation and the `toolTappedBlock` property for setting a
   callback block.

 - Set a custom gesture target to recognize and respond to other gestures.  (Convert touch
   locations to this node's coordinate system and call `toolAtLocation` as desired.)

 - Leave the gesture target unset for no gesture handling.
*/
@interface HLToolbarNode : HLComponentNode <NSCoding, HLGestureTarget>

/// @name Creating a Toolbar Node

/**
 Initializes a toolbar node.
*/
- (instancetype)init NS_DESIGNATED_INITIALIZER;

/// @name Managing Interaction

/**
 The delegate invoked on interaction (when this node is its own gesture handler).

 Unless this toolbar node is its own gesture handler, this delegate will not be called.
 See "Common Gesture Handling Configurations".
*/
@property (nonatomic, weak) id <HLToolbarNodeDelegate> delegate;

/**
 A callback invoked when a tool is tapped (when this node is its own gesture handler).

 The tag of the tapped tool is passed as an argument to the callback.

 Unless this toolbar node is its own gesture handler, this callback will not be invoked.
 See "Common Gesture Handling Configurations".

 Beware retain cycles when using the callback to invoke a method in the owner.  As a safer
 alternative, use the toolbar node's delegation interface; see `setDelegate:`.
 */
@property (nonatomic, copy) void (^toolTappedBlock)(NSString *toolTag);

/// @name Getting and Setting Tools

/**
 Sets tool nodes in the toolbar and effects layout according to all object properties.

 The square node that holds each tool has `anchorPoint` `(0.5, 0.5)`.

 Any `SKNode` descendant may be used as a tool, but any tools which conform to `HLToolNode`
 can customize their behavior and/or appearance for certain toolbar functions (for example,
 setting enabled or highlight); see `HLToolNode` for details.

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
   `automaticToolsScaleLimit` is `YES`, then the scaling of the tools will not exceed their
   natural size.

 - If only `automaticHeight` is `YES`, and toolbar width is fixed, the toolbar will scale
   the tool nodes proportionally to each other so that the sum of tool node widths will
   fit the toolbar width (plus relevant pads and borders).  If `automaticToolsScaleLimit`
   is `YES`, then the scaling of the tools will not exceed their natural size.

 - Otherwise, with both toolbar width and height fixed, the toolbar will scale the tools
   proportionally so they fit into both the fixed width and fixed height.  If
   `automaticToolsScaleLimit` is `YES`, then the scaling of the tools will not exceed their
   natural size.

 @param tools The array of `SKNode`s to be set as tools.

 @param toolTags An array of same length as tools containing strings to be used as
                 identifiers for the tools.  These tags (rather than, for example, indexes
                 in the array) are used in all other interfaces in this object interacting
                 with particular tools.

 @param animation Animation, if any.  See `HLToolbarNodeAnimation`.
*/
- (void)setTools:(NSArray *)tools tags:(NSArray *)toolTags animation:(HLToolbarNodeAnimation)animation;

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
- (SKSpriteNode *)squareNodeForTool:(NSString *)toolTag;

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

 If the tool node conforms to `HLToolNode` implementing `hlToolSetHighlight`, then that
 method will be called.  Otherwise, the color of the square will be set either
 to `highlightColor` or `squareColor`.
*/
- (void)setHighlight:(BOOL)highlight forTool:(NSString *)toolTag;

/**
 Convenience method for toggling the current highlight state of a tool.
*/
- (void)toggleHighlightForTool:(NSString *)toolTag;

/**
 Sets the highlight state of a tool with animation.

 If the tool node conforms to `HLToolNode` implementing `hlToolSetHighlight`, then that
 method will be called.  Otherwise, the color of the square will be set either
 to `highlightColor` or `squareColor`.

 Throws an exception if the square index is out of bounds.

 @param finalHighlight The intended highlight value for the square when the animation is
                       complete.

 @param toolTag The tag of the tool being animated.

 @param blinkCount The number of times the highlight value will cycle from its current
                   value to the final value.

 @param halfCycleDuration The amount of time it takes to cycle the highlight during a
                          blink; a full blink will be completed in twice this duration.
*/
- (void)setHighlight:(BOOL)finalHighlight forTool:(NSString *)toolTag blinkCount:(int)blinkCount halfCycleDuration:(NSTimeInterval)halfCycleDuration;

/**
 Returns a boolean indicating the current enabled state of a tool.
*/
- (BOOL)enabledForTool:(NSString *)toolTag;

/**
 Sets the enabled state of a tool.

 If the tool node conforms to `HLToolNode` implementing `hlToolSetEnabled`, then that
 method will be called.  Otherwise, the alpha value of the square will be set either
 to `enabledAlpha` or `disabledAlpha`.
*/
- (void)setEnabled:(BOOL)enabled forTool:(NSString *)toolTag;

/// @name Showing or Hiding Toolbar in Parent

/**
 Shows the toolbar at a given position and scale.

 When showing is animated, the toolbar will grow from a point to the passed `fullScale`,
 moving from `origin` to `finalPosition`.  (When not animated, the toolbar merely sets
 its position and scale.)

 The origin is remembered and is used by the next animated `hideAnimated:`.  To update
 the remembered last origin (for example, after changing the scene's layout), call
 `showUpdateOrigin:`.
*/
- (void)showWithOrigin:(CGPoint)origin finalPosition:(CGPoint)finalPosition fullScale:(CGFloat)fullScale animated:(BOOL)animated;

/**
 Updates the remembered origin from the last call to `showWithOrigin:finalPosition:fullScale:animated:`.
 The origin will be used by the next `hideAnimated:`.

 Showing a toolbar animated grows it from a point origin to a final position; hiding
 it animated shrinks it back down to that original origin.  It's considered a feature
 that the origin used for showing is remembered by the toolbar, and doesn't have to
 be passed back into the hide method, but of course such a system introduces difficulty
 if the origin needs to be changed between the show call and the hide call.  If so,
 then call this method to update the origin before calling `hideAnimated:`.
*/
- (void)showUpdateOrigin:(CGPoint)origin;

/**
 Hides the toolbar by removing it from parent.

 When hiding is animated, the toolbar will scale down and move to its last origin
 (passed during `[showWithOrigin:finalPosition:fullScale:animated:]`).  For consistency,
 the position of the toolbar is set likewise even when not animating.  This means that
 any explicit changes to toolbar position will be discarded during the call to `[hideAnimated:]`.
 The caller might consider calling `[showUpdateOrigin:]`, to change the stored origin.
*/
- (void)hideAnimated:(BOOL)animated;

@end

/**
 A delegate for `HLToolbarNode`.

 The delegate is (currently) concerned mostly with handling user interaction.  It's worth
 noting that the `HLToolbarNode` only receives gestures if it is configured as its own
 gesture target (using `[SKNode+HLGestureTarget hlSetGestureTarget]`).
 */
@protocol HLToolbarNodeDelegate <NSObject>

/// @name Handling User Interaction

/**
 Called when the user taps a tool.
*/
- (void)toolbarNode:(HLToolbarNode *)toolbarNode didTapTool:(NSString *)toolTag;

@end
