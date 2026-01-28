//
//  HLWrapLayoutManager.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 3/12/24.
//  Copyright © 2024 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLLayoutManager.h"

/**
 The fill mode for the wrap: the direction and priority for filling nodes into the columns
 and rows of the wrap.
*/
typedef NS_ENUM(NSInteger, HLWrapLayoutManagerFillMode) {
  /**
   Starting at the upper left of the wrap, nodes fill the first row rightwards before
   going down to the next row.
  */
  HLWrapLayoutManagerFillRightThenDown,
  /**
   Starting at the lower left of the wrap, nodes fill the first row rightwards before
   going up to the next row.
  */
  HLWrapLayoutManagerFillRightThenUp,
  /**
   Starting at the upper right of the wrap, nodes fill the first row leftwards before
   going down to the next row.
  */
  HLWrapLayoutManagerFillLeftThenDown,
  /**
   Starting at the lower right of the wrap, nodes fill the first row leftwards before
   going up to the next row.
  */
  HLWrapLayoutManagerFillLeftThenUp,
  /**
   Starting at the upper left of the wrap, nodes fill the first column downwards before
   going right to the next column.
  */
  HLWrapLayoutManagerFillDownThenRight,
  /**
   Starting at the upper right of the wrap, nodes fill the first column downwards before
   going left to the next column.
  */
  HLWrapLayoutManagerFillDownThenLeft,
  /**
   Starting at the lower left of the wrap, nodes fill the first column upwards before
   going right to the next column.
  */
  HLWrapLayoutManagerFillUpThenRight,
  /**
   Starting at the lower right of the wrap, nodes fill the first column upwards before
   going left to the next column.
  */
  HLWrapLayoutManagerFillUpThenLeft,
};

/**
 The justification of nodes within a line.

 Justification is specified relative to the primary fill direction.  For instance,
 if the `fillMode` is `HLWrapLayoutManagerFillRight*`, then a "near" justification
 means that lines of nodes will be aligned along their left edges.
*/
typedef NS_ENUM(NSInteger, HLWrapLayoutManagerJustification) {
  HLWrapLayoutManagerJustificationNear,
  HLWrapLayoutManagerJustificationCenter,
  HLWrapLayoutManagerJustificationFar,
};

/**
 Provides functionality to lay out (set positions of) nodes in wrapped rows or columns.
 This manager may be attached to an `SKNode` using `[SKNode+HLLayoutManager
 hlSetLayoutManager]`.
*/
@interface HLWrapLayoutManager : NSObject <HLLayoutManager, NSCopying, NSCoding>

/// @name Creating a Wrap Layout Manager

/**
 Initializes an unconfigured wrap layout manager.
*/
- (instancetype)init;

/**
 Initializes the layout manager with parameters for a simple wrap layout of nodes.
*/
- (instancetype)initWithFillMode:(HLWrapLayoutManagerFillMode)fillMode
                   maximumLength:(CGFloat)maximumLength
                   justification:(HLWrapLayoutManagerJustification)justification
                   lineSeparator:(CGFloat)lineSeparator;

/// @name Performing a Layout

/**
 Set the positions of all passed nodes according to the layout-affecting parameters.

 The order of the passed nodes determines position in the wrap, according to the
 `fillMode` of the wrap layout.

 This method must always be called explicitly to realize layout changes.  On one hand,
 it's annoying to have to remember to call it; on the other hand, it allows the owner
 efficiently to make multiple changes and re-layout only exactly once.
*/
- (void)layout:(NSArray *)nodes;

/// @name Getting and Setting Wrap Geometry

/**
 The fill mode used when laying out nodes into the columns and rows of the wrap layout.

 See `HLWrapLayoutManagerFillMode`.
*/
@property (nonatomic, assign) HLWrapLayoutManagerFillMode fillMode;

/**
 The maximum length of each line (including nodes, borders, and separators) before the
 layout manager wraps to the next line.  (Lines are either rows or columns depending on
 `fillMode`.)

 If a node (and border) is too large to fit into `maximumLength`, then it will be laid
 out alone in its line.

 Default value is `0.0`, which is not a useful value.
*/
@property (nonatomic, assign) CGFloat maximumLength;

/**
 The justification of nodes within a line.
*/
@property (nonatomic, assign) HLWrapLayoutManagerJustification justification;

/**
 The distance between each line of the wrap layout.

 In particular: All nodes in a line are laid out with the same X or Y position value
 (depending on whether the line is vertical or horizonal).  That X or Y value is offset by
 `lineSeparator` in the adjacent lines.

 Default value is `0.0`, which is not a useful value.
 */
@property (nonatomic, assign) CGFloat lineSeparator;

/**
 The anchor point used for the wrap layout.

 For example, if the `anchorPoint` is `(0.5, 0.5)`, the wrap layout will be centered on
 position `CGPointZero` plus the `wrapPosition`.

 The size of the wrap layout that is anchored by this property is the same as the `size`
 property.  This can be misleading; see note at `size`.

 Default value is `(0.5, 0.5)`.
*/
@property (nonatomic, assign) CGPoint anchorPoint;

/**
 A conceptual position used for the wrap layout, in scene point coordinate space.

 For example, if the `wrapPosition` is `(10.0, 0.0)`, all nodes laid out will have ten
 points added to their `position.x`.

 Default value is `(0.0, 0.0)`.
*/
@property (nonatomic, assign) CGPoint wrapPosition;

/**
 The anchor point used for setting the position of each node in its line.

 Since each line is laid out in only one dimension, each cell has only one anchor point
 value, either X or Y depending on whether the line is horizontal or vertical.

 When performing a layout, the wrap layout manager allocates a cell (of a certain length)
 for each node.  The node is then positioned in that cell according to the cell anchor
 point.  For horizontal lines, anchor point `0.0` is the left edge of the cell and `1.0`
 is the right edge; for vertical lines, anchor point `0.0` is the bottom edge of the cell
 and `1.0` is the top edge; for both, anchor point `0.5` is the center of the cell.

 For now, all cells in a wrap layout must share the same anchor point, which probably
 corresponds closely to the nodes that will be laid out: the anchor point of all the
 sprite nodes and the alignment modes of all the label nodes.  It's worth noting, though,
 that the layout manager ignores the current anchor points or alignments of the nodes
 during layout.

 Default value is `0.5`.
*/
@property (nonatomic, assign) CGFloat cellAnchorPoint;

/**
 The distance (reserved by `layout:`) on both ends of the lines of nodes in the overall
 wrap layout.

 This double border is added to the calculated line length when comparing to
 `maximumLength`.  For example, a `wrapBorder` of `10` and a single node of length `100`
 would only just fit into a `maximumLength` of `120`.

 Default value is `0.0`.
*/
@property (nonatomic, assign) CGFloat wrapBorder;

/**
 The distance (reserved by `layout:`) between adjacent nodes.

 These separators are added to the calculated line length when comparing to
 `maximumLength`.  For example, three nodes with length `100` and a `cellSeparator` of
 `10` would only just fit into a `maximumLength` of `320`.

 Default value is `0.0`.
*/
@property (nonatomic, assign) CGFloat cellSeparator;

/// @name Accessing Last-Layout State

/**
 Returns the calculated size of the wrap at the last layout.

 The size is derived from the layout-affecting parameters and last-laid-out nodes.

 This property is included in the layout manager to be consistent with other layout
 managers, but its size is possibly misleading in both dimensions.  In the dimension of
 the lines (either horizontal or vertical depending on `fillMode`), the size is the
 largest line length (including borders and separators).  In the other dimension, the size
 is the distance from the first line to the last (since the wrap manager is not aware of
 extent of the nodes in that dimension).
*/
@property (nonatomic, readonly) CGSize size;

@end
