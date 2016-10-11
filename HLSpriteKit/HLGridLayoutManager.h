//
//  HLGridLayoutManager.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/11/16.
//  Copyright (c) 2016 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLLayoutManager.h"

/**
 The fill mode for the grid: the direction and priority for filling nodes into the columns
 and rows of the grid.
*/
typedef NS_ENUM(NSInteger, HLGridLayoutManagerFillMode) {
  /**
   Starting at the upper left of the grid, nodes fill the first row rightwards before
   going down to the next row.
  */
  HLGridLayoutManagerFillRightThenDown,
  /**
   Starting at the lower left of the grid, nodes fill the first row rightwards before
   going up to the next row.
   */
  HLGridLayoutManagerFillRightThenUp,
  /**
   Starting at the upper right of the grid, nodes fill the first row leftwards before
   going down to the next row.
  */
  HLGridLayoutManagerFillLeftThenDown,
  /**
   Starting at the lower right of the grid, nodes fill the first row leftwards before
   going up to the next row.
   */
  HLGridLayoutManagerFillLeftThenUp,
  /**
   Starting at the upper left of the grid, nodes fill the first column downwards before
   going right to the next row.
  */
  HLGridLayoutManagerFillDownThenRight,
  /**
   Starting at the upper right of the grid, nodes fill the first column downwards before
   going left to the next row.
   */
  HLGridLayoutManagerFillDownThenLeft,
  /**
   Starting at the lower left of the grid, nodes fill the first column upwards before
   going right to the next row.
  */
  HLGridLayoutManagerFillUpThenRight,
  /**
   Starting at the lower right of the grid, nodes fill the first column upwards before
   going left to the next row.
   */
  HLGridLayoutManagerFillUpThenLeft,
};

/**
 Provides functionality to lay out (set positions of) nodes in a simple grid.  This
 manager may be attached to an `SKNode` using `[SKNode+HLLayoutManager
 hlSetLayoutManager]`.
*/
@interface HLGridLayoutManager : NSObject <HLLayoutManager, NSCopying, NSCoding>

/// @name Creating a Grid Layout Manager

/**
 Initializes an unconfigured grid layout manager.
*/
- (instancetype)init;

/**
 Initializes the object with all parameters necessary for a grid layout of nodes limited
 by the number of columns in the grid.
*/
- (instancetype)initWithColumnCount:(NSUInteger)columnCount
                         squareSize:(CGSize)squareSize;

/**
 Initializes the object with all parameters necessary for a grid layout of nodes limited
 by the number of rows in the grid.
*/
- (instancetype)initWithRowCount:(NSUInteger)rowCount
                      squareSize:(CGSize)squareSize;

/// @name Performing a Layout

/**
 Set the positions of all passed nodes according to the layout-affecting parameters.

 For layout to have an effect: Either `columnCount` or `rowCount` must have been set
 non-zero.  Grid layout is limited either by the number of columns or the number of rows;
 whichever property was most recently set determines the limiting dimension.

 The order of the passed nodes determines position in the grid, according to the
 `fillMode` of the grid.  A square is skipped if the corresponding element in the array is
 not a kind of `SKNode` class.  (It is suggested to pass `[NSNull null]` to intentionally
 leave squares empty.)

 This method must always be called explicitly to realize layout changes.  On one hand,
 it's annoying to have to remember to call it; on the other hand, it allows the owner
 efficiently to make multiple changes (e.g. remove a node, insert another node, change the
 `squareSeparator`, etc) and re-layout only exactly once.
*/
- (void)layout:(NSArray *)nodes;

/// @name Getting and Setting Grid Geometry

/**
 The anchor point used for the grid during layout.

 Default value is `(0.5, 0.5)`.

 For example, if the `anchorPoint` is `(0.5, 0.5)`, the grid will be centered on position
 `CGPointZero` plus the `gridOffset`.
*/
@property (nonatomic, assign) CGPoint anchorPoint;

/**
 A constant offset used for the grid during layout.

 Default value is `(0.0, 0.0)`.

 For example, if the `gridOffset` is `(10.0, 0.0)`, all nodes laid out will have ten
 points added to their `position.x`.
*/
@property (nonatomic, assign) CGPoint gridOffset;

/**
 The number of columns in the grid.

 Default value is `0`.

 The grid is constrained either by the number of columns or by the number of rows in the
 grid.  There is therefore an important distinction between setting and getting this
 property:

 - Setting the column count affects the next layout, limiting the number of columns in the
   grid and removing any row limitation (from `rowCount`).

 - Getting the column count returns the number of columns used by the nodes laid out at
   the last layout.
*/
@property (nonatomic, assign) NSUInteger columnCount;

/**
 The number of rows in the grid.

 Default value is `0`.

 The grid is constrained either by the number of columns or by the number of rows in the
 grid.  There is therefore an important distinction between setting and getting this
 property:

 - Setting the row count affects the next layout, limiting the number of rows in the grid
   and removing any column limitation (from `columnCount`).

 - Getting the row count returns the number of rows used by the nodes laid out at the last
   layout.
*/
@property (nonatomic, assign) NSUInteger rowCount;

/**
 The size reserved for each square in the grid.

 Default value is `CGSizeZero`.
*/
@property (nonatomic, assign) CGSize squareSize;

/**
 The anchor point used for setting the position of each node in the grid.

 Default value is `(0.5, 0.5)`.

 For example, if the `squareAnchorPoint` is centered, then each node will be positioned in
 the center of its calculated square in the grid.  However, if the square anchor point is
 `(0.0, 0.0)` (that is, lower left corner), then each node will be positioned in the lower
 left corner of its calculated square in the grid.
*/
@property (nonatomic, assign) CGPoint squareAnchorPoint;

/**
 The fill mode used when laying out nodes into the columns and rows of the grid.

 In particular: Are rows filled before columns, or columns before rows?  Are rows filled
 left-to-right or right-to-left?  Are columns filled upwards or downwards?

 See `HLGridLayoutManagerFillMode`.

 Default value is `HLGridLayoutManagerFillRightThenDown`.
*/
@property (nonatomic, assign) HLGridLayoutManagerFillMode fillMode;

/**
 The distance (reserved by `layout:`) between each edge of the grid and the nearest square
 edge.

 Default value is `0.0`.
*/
@property (nonatomic, assign) CGFloat gridBorder;

/**
 The distance (reserved by `layout:`) between adjacent squares.

 Default value is `0.0`.
*/
@property (nonatomic, assign) CGFloat squareSeparator;

/// @name Accessing Last-Layout State

/**
 Returns the calculated size of the grid at the last layout.

 The size is derived from the layout-affecting parameters and last-laid-out nodes.
*/
@property (nonatomic, readonly) CGSize size;

/**
 Convenience method for finding the index of the node containing the passed location, for
 nodes that have been laid out by this `HLGridLayoutManager`.

 Returns `NSNotFound` if no such node is found.

 Grid border and square separator are not considered to be contained by any node.
*/
NSUInteger HLGridLayoutManagerNodeContainingPoint(CGPoint location);

@end
