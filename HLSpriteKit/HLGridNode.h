//
//  HLGridNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/14/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLComponentNode.h"
#import "HLGestureTarget.h"

@protocol HLGridNodeDelegate;

/**
 The layout mode for the grid.  Primarily affects how squares are laid out when they
 don't fit exactly into rows.
*/
typedef NS_ENUM(NSInteger, HLGridNodeLayoutMode) {
  /**
   Squares in the last row of the grid are widened so that the row space is divided evenly among them.
  */
  HLGridNodeLayoutModeFill,
  /**
   Squares in the last row of the grid align to the left, perhaps leaving extra space
   on the right.
  */
  HLGridNodeLayoutModeAlignLeft,
};

/**
 `HLGridNode` is a component that lays out its content nodes in a grid of similarly-sized
 squares.  It includes various visual format options (like background color and square
 color) as well as geometry options (like pads and spacers).  The grid node tracks certain
 states for the squares (like highlight, enabled, and selection), and also provides some
 simple animations for state changes.

 ## Common Gesture Handling Configurations

 - Set this node as its own gesture target (using `[SKNode+HLGestureTarget
   hlSetGestureTarget]`) to get a simple delegation and/or callbacks for taps.  See
   `HLGridNodeDelegate` for delegation and the `squareTappedBlock` property for setting a
   callback block.

 - Set a custom gesture target to recognize and respond to other gestures.  (Convert touch
   locations to this node's coordinate system and call `squareAtLocation` as desired.)

 - Leave the gesture target unset for no gesture handling.
*/

@interface HLGridNode : HLComponentNode <HLGestureTarget>

/// @name Creating a Grid Node

/**
 Initialize a new grid node with values for all layout-affecting parameters.

 note: Currently the layout-affecting parameters are not properties, and so can't be set
 individually, which helps avoid the problem where layout is redone multiple times as
 each parameter is adjusted individually.

 TODO: Allow modification of layout-affecting parameters via properties, with a similar
 contract as other components: If the content is not set, then layout will not be
 performed.

 @param gridWidth The maximum number of squares to layout in a row.

 @param squareCount The total number of squares to create in the grid.

 @param anchorPoint The anchorPoint used to layout the grid around the `HLGridNode`'s
                    position.

 @param layoutMode The layout mode for the grid (pertaining chiefly to handling the layout
                   of squares that don't fit exactly into rows); see
                   `HLGridNodeLayoutMode`.

 @param squareSize The normal size of a square when it fits in a row; see
                   `HLGridNodeLayoutMode` for exceptions.

 @param backgroundBorderSize The distance, in pixels, between the edge of the background
                             and the nearest squares.

 @param squareSeparatorSize The distance, in pixels, between squares; the background
                            color shows through in this area.

 @return A configured `HLGridNode`.
*/
- (instancetype)initWithGridWidth:(int)gridWidth
                      squareCount:(int)squareCount
                      anchorPoint:(CGPoint)anchorPoint
                       layoutMode:(HLGridNodeLayoutMode)layoutMode
                       squareSize:(CGSize)squareSize
             backgroundBorderSize:(CGFloat)backgroundBorderSize
              squareSeparatorSize:(CGFloat)squareSeparatorSize NS_DESIGNATED_INITIALIZER;

/// @name Managing Interaction

/**
 The delegate invoked on interaction (when this node is its own gesture handler).

 Unless this grid node is its own gesture handler, this delegate will not be called.  See
 "Common Gesture Handling Configurations".
*/
@property (nonatomic, weak) id <HLGridNodeDelegate> delegate;

/**
 A callback invoked when a square in the grid is tapped (when this node is its own gesture
 handler).

 The index of the tapped square is passed as an argument to the callback.  (Square indexes
 start at zero for the top-left square in the grid, and then increase to the right row by
 row.)

 Unless this grid node is its own gesture handler, this callback will not be invoked.  See
 "Common Gesture Handling Configurations".

 Beware retain cycles when using the callback to invoke a method in the owner.  As a safer
 alternative, use the grid node's delegation interface; see `setDelegate:`.
*/
@property (nonatomic, copy) void (^squareTappedBlock)(int squareIndex);

/// @name Configuring Layout and Geometry

/**
 The width (column count) of the grid.

 The same value passed into `init` by the owner.  It is made available here (readonly) for
 the owner's convenience.
*/
@property (nonatomic, readonly) int gridWidth;

/**
 The height (row count) of the grid.

 This value is trivially derived from the `gridWidth` and `squareCount` passed into `init`
 by the owner.  It is made available here (readonly) for the owner's convenience.
*/
@property (nonatomic, readonly) int gridHeight;

/**
 The size of the overall grid node.

 This value is derived from the layout-affecting parameters.  (Currently the
 layout-affecting parameters are all passed into the `init` method.)
*/
@property (nonatomic, readonly) CGSize size;

/// @name Getting and Setting Content

/**
 Sets content nodes in the squares of the grid.

 As many nodes as fit in the grid will be set, starting at the upper left of the grid and
 filling rows before columns; the rest will be ignored.  A content node may be left unset
 by passing `[NSNull null]` in the appropriate position in the array.

 The square node that holds each content node has `anchorPoint` `(0.5, 0.5)`.  Typically
 the size of the square is `squareSize`; see `HLGridNodeLayoutMode` for exceptions.

 Any `SKNode` descendant may be used as a tool, but any tools which conform to `HLToolNode`
 can customize their behavior and/or appearance for certain toolbar functions (for example,
 setting enabled or highlight); see `HLToolNode` for details.
*/
- (void)setContent:(NSArray *)contentNodes;

/**
 Sets a single content node in a square of the grid, or unsets it if passed `nil`.

 See notes on `setContent:`.  Throws an exception if the square index is out of bounds.
*/
- (void)setContent:(SKNode *)contentNode forSquare:(int)squareIndex;

/**
 Returns the content node assigned to a square by `setContent:` or `setContent:forSquare:`.

 Returns `nil` if the content node was left unset.  Throws an exception if the square
 index is out of bounds.
*/
- (SKNode *)contentForSquare:(int)squareIndex;

/**
 Returns the square node for the passed square index.

 This is intended for callers that need to know specifics about the square node, such as
 bounding box for hit-testing purposes.  Throws an exception if the square index is out of
 bounds.

 @warning The returned node should be treated as read-only.  Modification of the square
          node is neither expected nor recommended.
*/
- (SKSpriteNode *)squareNodeForSquare:(int)squareIndex;

/**
 Returns the index of the square at the passed location, or `-1` for none.

 The location is expected to be in the coordinate system of this node.
*/
- (int)squareAtLocation:(CGPoint)location;

/// @name Configuring Appearance

/**
 The color that shows around the grid and between squares.

 The border around the grid and the space between squares are controlled by the
 `backgroundBorderSize` and `squareSeparatorSize` parameters passed to `init`.

 The `backgroundColor` is also drawn *behind* the squares, and so might blend, depending
 on the color and alpha of the square nodes.  Default value `[SKColor colorWithWhite:0.0
 alpha:0.5]`.
*/
@property (nonatomic, strong) SKColor *backgroundColor;

/**
 The color of grid squares in normal state.

 This color shows behind content in each grid square when the square is in a normal state
 (that is, not highlighted or in some other special state).  Default value `[SKColor
 colorWithWhite:1.0 alpha:0.3]`.
*/
@property (nonatomic, strong) SKColor *squareColor;

/**
 The color of grid squares in highlighted state.

 This color shows behind content in each grid square when the square is highlighted by
 `setHighlight`.  Default value `[SKColor colorWithWhite:1.0 alpha:0.6]`.
*/
@property (nonatomic, strong) SKColor *highlightColor;

/**
 The alpha of the grid square in enabled state.

 The alpha value is applied to the square node regardless of the square's current color,
 and thus it will multiply with the color's alpha.

 Default value `1.0`.
*/
@property (nonatomic, assign) CGFloat enabledAlpha;

/**
 The alpha of the grid square in disabled state.

 The alpha value is applied to the square node regardless of the square's current color,
 and thus it will multiply with the color's alpha.

 Default value `0.4`.
*/
@property (nonatomic, assign) CGFloat disabledAlpha;

/// @name Managing Grid Square State

/**
 Returns a boolean indicating whether a square is enabled.

 Throws an exception if the square index is out of bounds.
*/
- (BOOL)enabledForSquare:(int)squareIndex;

/**
 Sets the enabled state of a square.

 The alpha value of the square will be set either to `enabledAlpha` or `disabledAlpha`
 regardless of the square's current color.  Throws an exception if the square index is out
 of bounds.
*/
- (void)setEnabled:(BOOL)enabled forSquare:(int)squareIndex;

/**
 Returns a boolean indicating the current highlight state of a square.

 Throws an exception if the square index is out of bounds.
*/
- (BOOL)highlightForSquare:(int)squareIndex;

/**
 Sets the highlight state of a square.

 The color of the square will be set either to `highlightColor` or `squareColor`.  Throws
 an exception if the square index is out of bounds.
*/
- (void)setHighlight:(BOOL)highlight forSquare:(int)squareIndex;

/**
 Sets the highlight state of a square with animation.

 The color of the square will be set either to `highlightColor` or `squareColor`.  Throws
 an exception if the square index is out of bounds.

 @param finalHighlight The intended highlight value for the square when the animation is
                       complete.

 @param squareIndex The index of the square being animated.  (Square indexes start at zero
                    for the top-left square in the grid, and then increase to the right
                    row by row.)

 @param blinkCount The number of times the highlight value will cycle from its current
                   value to the final value.

 @param halfCycleDuration The amount of time it takes to fade in or fade out during a
                          blink; a full blink will be completed in twice this duration.

 @param completion A block that will be run when the animation is complete.
*/
- (void)setHighlight:(BOOL)finalHighlight
           forSquare:(int)squareIndex
          blinkCount:(int)blinkCount
   halfCycleDuration:(NSTimeInterval)halfCycleDuration
          completion:(void(^)(void))completion;

/**
 Convenience method for returning the index of the square last selected; see
 `setSelectionForSquare:`.

 Returns -1 if no square is currently selected.
*/
- (int)selectionSquare;

/**
 Convenience method for setting the highlight state of a single square.

 Sets highlight `YES` for the passed square, and sets highlight `NO` for the previously
 selected square (if any).
*/
- (void)setSelectionForSquare:(int)squareIndex;

/**
 Convenience method for setting the highlight state of a single square with animation.

 Animates highlight `YES` for the passed square, and sets highlight `NO` (with no
 animation) for the previously-selected square (if any).
*/
- (void)setSelectionForSquare:(int)squareIndex
                   blinkCount:(int)blinkCount
            halfCycleDuration:(NSTimeInterval)halfCycleDuration
                   completion:(void(^)(void))completion;

/**
 Convenience method for setting highlight state of a single square.

 Clears the highlight of the last-selected square, if any.
*/
- (void)clearSelection;

/**
 Convenience method for setting the highlight state of a single square with animation.
 
 Clears the highlight of the last-selected square, if any, with animation.
*/
- (void)clearSelectionBlinkCount:(int)blinkCount
               halfCycleDuration:(NSTimeInterval)halfCycleDuration
                      completion:(void(^)(void))completion;

@end

/**
 A delegate for `HLGridNode`.

 The delegate is (currently) concerned mostly with handling user interaction.  It's worth
 noting that the `HLGridNode` only receives gestures if it is configured as its own
 gesture target (using `[SKNode+HLGestureTarget hlSetGestureTarget]`).
 */
@protocol HLGridNodeDelegate <NSObject>

/// @name Handling User Interaction

/**
 Called when the user taps on a square in the grid.
*/
- (void)gridNode:(HLGridNode *)gridNode didTapSquare:(int)squareIndex;

@end
