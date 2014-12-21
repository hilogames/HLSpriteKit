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

@class HLTextureStore;

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
   hlSetGestureTarget]`) to get a simple callback for taps via the `toolTappedBlock`
   property.
 
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
 A callback invoked when a tool is tapped.
 
 The callback parameter is passed as the tag of the tapped tool.
 
 note: For now, use callbacks rather than delegation.
 */
@property (nonatomic, copy) void (^toolTappedBlock)(NSString *toolTag);

/// @name Getting and Setting Tools

/**
 Sets tool nodes in the toolbar and effects layout according to all object properties.

 The square node that holds each tool has `anchorPoint` `(0.5, 0.5)`.

 Each tool node is expected to have a size selector which reports its desired size.  (The
 size is expected to behave like `[SKSpriteNode size]` property, where the `SKNode`
 `xScale` and `yScale` are already reflected in the reported size, but the `SKNode`
 `zRotation` is not.)  Depending on other object properties, either the tools will be
 scaled to fit the toolbar or vice versa.  In particular:

 - If `automaticWidth` and `automaticHeight` are both `YES`, the toolbar will set its
   height to the maximum tool node height (plus relevant pads and borders) and its width
   to the sum of the tool node widths (plus relevant pads and borders).

 - If only `automaticWidth` is `YES`, and toolbar height is fixed, the toolbar will scale
   the tool nodes so that the tallest tool node will fit the toolbar height (plus relevant
   pads and borders), and the others will be scaled proportionally.

 - If only `automaticHeight` is `YES`, and toolbar width is fixed, the toolbar will scale
   the tool nodes proportionally to each other so that the sum of tool node widths will
   fit the toolbar width (plus relevant pads and borders).

 - Otherwise, with both toolbar width and height fixed, the toolbar will scale the tools
   proportionally so they fit into both the fixed width and fixed height.

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

 Changes will not take effect until the next call to `setTools:tags:animation:`.
 Default is `[SKColor colorWithWhite:0.0 alpha:0.5]`.
*/
@property (nonatomic, strong) SKColor *backgroundColor;

/**
 Tool square color, showing behind each tool node set.

 Changes will not take effect until the next call to `setTools:tags:animation:`.
 Default is `[SKColor colorWithWhite:0.7 alpha:0.5]`.
*/
@property (nonatomic, strong) SKColor *squareColor;

/**
 Tool square color when highlighted.

 Changes will not take effect for already-highlighted tools until the next call to
 `setTools:tags:animation:`.  Default is `[SKColor colorWithWhite:1.0 alpha:0.8]`.
*/
@property (nonatomic, strong) SKColor *highlightColor;

/**
 Alpha value for tool square (and inherited by tool node in square) when tool is enabled.

 Changes will not take effect for already-enabled tools until the next call to
 `setTools:tags:animation:`.
*/
@property (nonatomic, assign) CGFloat enabledAlpha;

/**
 Alpha value for tool square (and inherited by tool node in square) when tool is
 disabled.

 Changes won't take effect until after the next call to `setTools:tags:animation:`; since
 all tools are enabled in `setTools:tags:animation:`, already-disabled tools will not be
 affected.
*/
@property (nonatomic, assign) CGFloat disabledAlpha;

/// @name Configuring Toolbar Geometry

/**
 Whether the toolbar should automatically size its width according to its tools.

 Default value is `NO`.

 See `setTools:tags:animation:` for details.
*/
@property (nonatomic, assign) BOOL automaticWidth;

/**
 Whether the toolbar should automatically size its height according to its tools.

 Default value is `NO`.

 See `setTools:tags:animation:` for details.
*/
@property (nonatomic, assign) BOOL automaticHeight;

/**
 Overall toolbar size.

 If `automaticWidth` or `automaticHeight` are `YES`, the relevant dimension may be changed
 during calls to `setTools:tags:animation:`.
*/
@property (nonatomic, assign) CGSize size;

/**
 The anchor point used by the toolbar.
*/
@property (nonatomic, assign) CGPoint anchorPoint;

/**
 The justification of tools within the toolbar.

 See `HLToolbarNodeJustification`.
*/
@property (nonatomic, assign) HLToolbarNodeJustification justification;

/**
 The amount of toolbar background that shows as a border around the outside tool
 squares.

 Default value is `4.0`.

 Changes will not take effect until the next call to `setTools:tags:animation:`.
*/
@property (nonatomic, assign) CGFloat backgroundBorderSize;

/**
 The amount of toolbar background that shows between each tool square on the toolbar.

 Default value is `4.0`.

 Changes will not take effect until the next call to `setTools:tags:animation:`.
*/
@property (nonatomic, assign) CGFloat squareSeparatorSize;

/**
 The extra space added between the edge of the tool square (made for each tool) and the
 user-supplied tool node itself.

 Negative values mean the tool square will be drawn smaller than the tool node.  Changes
 will not take effect until the next call to `setTools:tags:animation:`.
*/
@property (nonatomic, assign) CGFloat toolPad;

/// @name Managing Tool State

- (void)setHighlight:(BOOL)highlight forTool:(NSString *)toolTag;

- (void)setHighlight:(BOOL)finalHighlight forTool:(NSString *)toolTag blinkCount:(int)blinkCount halfCycleDuration:(NSTimeInterval)halfCycleDuration;

- (void)setEnabled:(BOOL)enabled forTool:(NSString *)toolTag;

- (BOOL)enabledForTool:(NSString *)toolTag;

/// @name Showing or Hiding Toolbar in Parent

- (void)showWithOrigin:(CGPoint)origin finalPosition:(CGPoint)finalPosition fullScale:(CGFloat)fullScale animated:(BOOL)animated;

- (void)showUpdateOrigin:(CGPoint)origin;

/**
 Hides the toolbar by removing it from parent.
 
 When hiding is animated, the toolbar will scale down and move to its last origin
 (passed during `[showWithOrigin:finalPosition:fullScale:animated:]`).  For consistency,
 the position of the toolbar is set likewise even when not animating.  This means that
 any explicit changes to toolbar position will be discarded during the call to `[hideAnimated:]`.
 the caller might consider calling `[showUpdateOrigin:]`, to change the stored origin.
*/
- (void)hideAnimated:(BOOL)animated;

@end
