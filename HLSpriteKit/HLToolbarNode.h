//
//  HLToolbarNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 12/12/13.
//  Copyright (c) 2013 Hilo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@class HLTextureStore;

typedef enum HLToolbarNodeJustification {
  HLToolbarNodeJustificationCenter,
  HLToolbarNodeJustificationLeft,
  HLToolbarNodeJustificationRight
} HLToolbarNodeJustification;

typedef enum HLToolbarNodeAnimation {
  HLToolbarNodeAnimationNone,
  HLToolbarNodeAnimationSlideUp,
  HLToolbarNodeAnimationSlideDown,
  HLToolbarNodeAnimationSlideLeft,
  HLToolbarNodeAnimationSlideRight
} HLToolbarNodeAnimation;

@interface HLToolbarNode : SKNode <NSCoding>

/**
 * Main toolbar color, showing as background behind tool squares.  Changes will not take
 * effect until the next call to setTools.
 */
@property (nonatomic, strong) SKColor *backgroundColor;

/**
 * Tool square color, showing behind each tool node set.  Changes will not take effect
 * until the next call to setTools.
 */
@property (nonatomic, strong) SKColor *squareColor;

/**
 * Tool square color when highlighted.  Changes will not take effect for
 * already-highlighted tools until the next call to setTools.
 */
@property (nonatomic, strong) SKColor *highlightColor;

/**
 * Alpha value for tool square (and inherited by tool node in square) when tool is
 * enabled.  Changes will not take effect for already-enabled tools until the next call to
 * setTools.
 */
@property (nonatomic, assign) CGFloat enabledAlpha;

/**
 * Alpha value for tool square (and inherited by tool node in square) when tool is
 * disabled.  Changes won't take effect until after the next call to setTools; since all
 * tools are enabled in setTools, already-disabled tools will not be affected.
 */
@property (nonatomic, assign) CGFloat disabledAlpha;

/**
 * Whether the toolbar should automatically size its width according to its tools.  See
 * setTools for details.
 */
@property (nonatomic, assign) BOOL automaticWidth;

/**
 * Whether the toolbar should automatically size its height according to its tools.  See
 * setTools for details.
 */
@property (nonatomic, assign) BOOL automaticHeight;

/**
 * Overall toolbar size.  If automaticWidth or automaticHeight are YES, the relevant
 * dimension may be changed during calls to setTools.
 */
@property (nonatomic, assign) CGSize size;

@property (nonatomic, assign) CGPoint anchorPoint;

@property (nonatomic, assign) HLToolbarNodeJustification justification;

/**
 * The amount of toolbar background that shows as a border around the outside tool
 * squares.  Changes will not take effect until the next call to setTools.
 */
@property (nonatomic, assign) CGFloat backgroundBorderSize;

/**
 * The amount of toolbar background that shows between each tool square on the toolbar.
 * Changes will not take effect until the next call to setTools.
 */
@property (nonatomic, assign) CGFloat squareSeparatorSize;

/**
 * The extra space added between the edge of the tool square (made for each tool) and the
 * user-supplied tool node itself.  Negative values mean the tool square will be drawn
 * smaller than the tool node.  Changes will not take effect until the next call to
 * setTools.
 */
@property (nonatomic, assign) CGFloat toolPad;

/**
 * Sets tool nodes in the toolbar and effects layout according to all object properties.
 *
 * The square node that holds each tool has anchorPoint (0.5, 0.5).
 *
 * Each tool node is expected to have a size selector which reports its desired size.
 * (The size is expected to behave like SKSpriteNode's size property, where the SKNode
 * xScale and yScale are already reflected in the reported size, but the SKNode zRotation
 * is not.)  Depending on other object properties, either the tools will be scaled to fit
 * the toolbar or vice versa.  In particular:
 *
 *   . If automaticWidth and automaticHeight are both YES, the toolbar will set its height
 *     to the maximum tool node height (plus relevant pads and borders) and its width to
 *     the sum of the tool node widths (plus relevant pads and borders).
 *
 *   . If only automaticWidth is YES, and toolbar height is fixed, the toolbar will scale
 *     the tool nodes so that the tallest tool node will fit the toolbar height (plus
 *     relevant pads and borders), and the others will be scaled proportionally.
 *
 *   . If only automaticHeight is YES, and toolbar width is fixed, the toolbar will scale
 *     the tool nodes proportionally to each other so that the sum of tool node widths
 *     will fit the toolbar width (plus relevant pads and borders).
 *
 *   . Otherwise, with both toolbar width and height fixed, the toolbar will scale the
 *     tools proportionally so they fit into both the fixed width and fixed height.
 *
 * @param The array of SKNodes to be set as tools.
 *
 * @param An array of same length as tools containing strings to be used as identifiers
 *        for the tools.  These tags (rather than, for example, indexes in the array)
 *        are used in all other interfaces in this object interacting with particular tools.
 *
 * @param Animation, if any.  See HLToolbarNodeAnimation.
 */
- (void)setTools:(NSArray *)tools tags:(NSArray *)toolTags animation:(HLToolbarNodeAnimation)animation;

/**
 * Returns the tag of the tool at the passed location, or -1 for none.  The location is
 * expected to be in the coordinate system of this node.
 */
- (NSString *)toolAtLocation:(CGPoint)location;

- (CGRect)frameForTool:(NSString *)toolTag;

- (NSUInteger)toolCount;

- (void)setHighlight:(BOOL)highlight forTool:(NSString *)toolTag;

- (void)animateHighlight:(BOOL)finalHighlight count:(int)blinkCount halfCycleDuration:(NSTimeInterval)halfCycleDuration forTool:(NSString *)toolTag;

- (void)setEnabled:(BOOL)enabled forTool:(NSString *)toolTag;

- (BOOL)enabledForTool:(NSString *)toolTag;

- (void)showWithOrigin:(CGPoint)origin finalPosition:(CGPoint)finalPosition fullScale:(CGFloat)fullScale animated:(BOOL)animated;

- (void)hideAnimated:(BOOL)animated;

@end
