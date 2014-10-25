//
//  HLGridNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/14/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLComponentNode.h"
#import "HLGestureTarget.h"

@interface HLGridNode : HLComponentNode <HLGestureTarget, HLGestureTargetDelegate>

/**
 * Common gesture handling configurations:
 *
 *   - Set the gesture target delegate to the gesture target (this HLGridNode)
 *     to get a simple callback for taps via the squareTappedBlock property.
 *     (Set the delegate weakly to avoid retain cycles.)
 *
 *   - Set the gesture target delegate to an HLGestureTargetConfigurableDelegate
 *     or a custom delegate to recognize and respond to other gestures.
 *     (Convert touch locations to this node's coordinate system and call
 *     squareAtLocation as desired.)
 *
 *   - Leave the gesture target delegate unset for no gesture handling.
 *
 * note: The class was originally created with only the squareTappedBlock
 * option, but since then has been extended to allow for arbitrary gesture
 * target delegates.  Consider deprecating squareTappedBlock (and self-
 * delegation); the owner would use HLGestureTargetTapDelegate to get
 * almost-as-convenient functionality.
 */

/**
 * A callback invoked when a square in the grid is tapped.  The callback parameter is
 * passed as the index of the tapped square.  (Square indexes, here as elsewhere, start
 * at zero for the top-left square in the grid, and then increase to the right row by
 * row.)
 *
 * note: For now, use callbacks rather than delegation.
 */
@property (nonatomic, copy) void (^squareTappedBlock)(int squareIndex);

@property (nonatomic, strong) SKColor *backgroundColor;

@property (nonatomic, strong) SKColor *squareColor;

@property (nonatomic, strong) SKColor *highlightColor;

@property (nonatomic, assign) CGFloat enabledAlpha;
@property (nonatomic, assign) CGFloat disabledAlpha;

/**
 * Returns the size of the overall grid node, which is derived from the layout-affecting
 * parameters.  (Currently the layout-affecting parameters are all passed into the init
 * method.)
 */
@property (nonatomic, readonly) CGSize size;

/**
 * Returns the width of the grid (column count), which is passed into init by the owner.
 * It is made available here (readonly) for the owner's convenience.
 */
@property (nonatomic, readonly) int gridWidth;

/**
 * Returns the height of the grid (row count), which is trivially derived from the gridWidth
 * and squareCount passed into init by the owner.  It is made available here (readonly) for
 * the owner's convenience.
 */
@property (nonatomic, readonly) int gridHeight;

/**
 * The layout mode for the grid.  Primarily affects how squares are layed out when they
 * don't fit exactly into rows.
 *
 *   HLGridNodeLayoutModeFill: Squares in the last row of the grid are widened so that
 *                             the row space is divided evenly among them.
 *
 *   HLGridNodeLayoutModeAlignLeft: Squares in the last row of the grid align to the
 *                                  left, perhaps leaving extra space on the right.
 */
typedef NS_ENUM(NSInteger, HLGridNodeLayoutMode) {
  HLGridNodeLayoutModeFill,
  HLGridNodeLayoutModeAlignLeft,
};

/**
 * Initialize with values for layout-affecting parameters.
 *
 * note: Currently the layout-affecting parameters are not properties, and so can't be set
 * individually, which helps avoid the problem where layout is redone multiple times as
 * each parameter is adjusted individually.
 *
 * @param The maximum number of squares to layout in a row.
 *
 * @param The total number of squares to create in the grid.
 *
 * @param The layout mode for the grid (pertaining chiefly to handling the layout of
 *        squares that don't fit exactly into rows); see HLGridNodeLayoutMode.
 *
 * @param The normal size of a square when it fits in a row; see HLGridNodeLayoutMode
 *        for exceptions.
 *
 * @param The distance, in pixels, between the edge of the background and the nearest
 *        squares.
 *
 * @param The distance, in pixels, between squares; the background color shows through in
 *        this area.
 */
- (instancetype)initWithGridWidth:(int)gridWidth
                      squareCount:(int)squareCount
                       layoutMode:(HLGridNodeLayoutMode)layoutMode
                       squareSize:(CGSize)squareSize
             backgroundBorderSize:(CGFloat)backgroundBorderSize
              squareSeparatorSize:(CGFloat)squareSeparatorSize NS_DESIGNATED_INITIALIZER;

/**
 * Set content nodes in the squares of the grid.  As many nodes as fit in the grid will be
 * shown, starting at the upper left of the grid and filling rows before columns; the rest
 * will be ignored.  A content node may be left unset by passing [NSNull null] in the
 * appropriate position in the array.
 *
 * The square node that holds each content node has anchorPoint (0.5, 0.5).  Typically the
 * size of the square is squareSize; see HLGridNodeLayoutMode for exceptions.
 */
- (void)setContent:(NSArray *)contentNodes;

/**
 * Sets a single content node in a square of the grid, or unsets it if the content node
 * is passed as nil.  See notes on setContent:.  Throws an exception if the square index
 * is out of bounds.
 */
- (void)setContent:(SKNode *)contentNode forSquare:(int)squareIndex;

/**
 * Returns the content node assigned to a square by setContent*.  Returns nil if the content
 * node was left unset.  Throws an exception if the square index is out of bounds.
 */
- (SKNode *)contentForSquare:(int)squareIndex;

/**
 * Returns the square node for the passed square index.  Modification of the square node is
 * neither expected nor recommended.  Throws an exception if the square index is out of bounds.
 */
- (SKSpriteNode *)squareNodeForSquare:(int)squareIndex;

/**
 * Returns the index of the square at the passed location, or -1 for none.  The location
 * is expected to be in the coordinate system of this node.
 */
- (int)squareAtLocation:(CGPoint)location;

/**
 * Set enabled state of a square, setting its alpha either to enabledAlpha or
 * disabledAlpha.  Throws an exception if the square index is out of bounds.
 */
- (void)setEnabled:(BOOL)enabled forSquare:(int)squareIndex;

/**
 * Sets highlight state of a square, setting its color either to highlightColor or
 * squareColor.  Throws an exception if the square index is out of bounds.
 */
- (void)setHighlight:(BOOL)highlight forSquare:(int)squareIndex;

- (void)setHighlight:(BOOL)finalHighlight
           forSquare:(int)squareIndex
          blinkCount:(int)blinkCount
   halfCycleDuration:(NSTimeInterval)halfCycleDuration
          completion:(void(^)(void))completion;

/**
 * Convenience method for managing highlight of a single square: Sets highlight YES for
 * the passed square, and sets highlight NO for the previously selected square (if any).
 */
- (void)setSelectionForSquare:(int)squareIndex;

/**
 * Convenience method for managing highlight of a single square: Animates highlight YES
 * for the passed square, and sets highlight NO for the previously selected square (if
 * any).
 */
- (void)animateSelectionBlinkCount:(int)blinkCount
                 halfCycleDuration:(NSTimeInterval)halfCycleDuration
                         forSquare:(int)squareIndex
                        completion:(void(^)(void))completion;

/**
 * Convenience method for managing highlight of a single square: Clears the highlight of
 * the last-selected square, if any.
 */
- (void)clearSelection;

@end
