//
//  HLTableLayoutManager.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/27/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLLayoutManager.h"

FOUNDATION_EXPORT const CGFloat HLTableLayoutManagerEpsilon;

/**
 Provides functionality to lay out (set positions of) nodes in a table.  This manager may
 be attached to an `SKNode` using `[SKNode+HLLayoutManager hlSetLayoutManager]`.

 ### Aligning Labels in a Table

 Say you have a row of label nodes.  How do you vertically align the text?

   - It's easy to assign the same Y-position to nodes in a table row.

   - Therefore, it's easy to vertically align a row of label nodes using the
     `verticalAlignmentMode` property of the labels: baseline, top, center, or bottom.
     Baseline alignment is typical.

 Things get more complicated, however, in the following situations:

   1. When the row contains both label nodes and sprite nodes.

                  +-----+             +----+ +-----+
          Player  |#####|  Abilities  | /\ | | --> |
                  +-----+             +----+ +-----+

   2. When the text is enclosed visually by a box the same size as the row.

          +----------------------------------+
          |  Wave   3  of   10     Gold  15  |
          +----------------------------------+

 In these cases, baseline alignment for the label nodes is still typical.  The question
 is: Where should the baseline go relative to the sprite nodes (and/or enclosing box)?

 Well, the answer is: "Anywhere you want it to go."  Commonly, though, the goal is to
 **visually center** the text with the boxes.  In that case the answer is usually: "Down a
 few points."

 Probably you should not adjust anchor points in order to achive visual centering.  The
 Y-offset required to visually-center a label is related to the label's font geometry and
 size, and is unrelated to the heights of the nearby sprites or enclosing box.  In other
 words, it's a Y-offset in point coordinate space and not an anchor in unit coordinate
 space.

 Instead, calculate the offset for different kinds of visual centering using
 `baselineOffsetYFromVisualCenterForHeightMode:fontName:fontSize:` from
 `SKLabelNode+HLLabelNodeAdditions`.

 Then use `rowLabelOffsetYs` to configure the offset on the table.  It will automatically
 be applied to label nodes in the row, and not sprite nodes.

 Comments on usage:

   - The use-case for `rowLabelOffsetYs` is for (vertical) visual centering of
     baseline-aligned label nodes.

   - It is assumed (though not enforced) that all label nodes in the row will be using
     baseline alignment.

   - If a row in the table uses different or larger fonts (a header row, perhaps?) then
     its calculated visual-centering Y-offset will be different.  The table allows
     specification of different Y-offsets for each row.

   - If labels in different columns of the same row have different fonts or font sizes,
     however, there is no obvious solution.  Baseline-alignment within the row is probably
     the priority, and so a single offset is appropriate for the whole row -- but it's not
     clear exactly which offset to use.  Perhaps there is a "typical" font size; perhaps
     using an average offset would be good; or perhaps an anchor-point solution would be
     best after all.  (The helper
     `baselineInsetYFromBottomForHeightMode:fontName:fontSize:` deals with unit coordinate
     space insets, not offsets, and might be able to provide a good anchor point value.)

 Comments on possible alternate designs:

   - Rather than a label-only Y-offset, could specify offsets for each column.  But it's
     tedious to specify each column offset when it seems like it's always zero for sprites
     and the same constant for labels.  I even wrote a helper to generate the offsets, and
     it still felt tedious.  Needs a use-case.  Even if we did column offsets, we'd still
     need an additional per-row Y-offset to help with the problem of header rows.  Which
     would still be label-only.  Anchor point is almost always good enough for sprites.
     Which brings us back to the idea of using a struct to specify column alignments,
     rather than a CGPoint for the column anchor point.  Then the struct could include an
     anchor point, an offset, and various visual-centering options.  Or perhaps a functor
     of some kind which is applied to the position of each node after layout.

   - Could have more enhanced "automatic" offset options.  Like, you specify the height
     mode, and the offset is calculated automatically for the row (using the first-found
     label node?) and then applied to all label nodes in the row.  Maybe you could even
     specify a strategy for calculation -- use a fixed Y-offset for all rows, or a fixed
     Y-offset for each row, or calculate a Y-offset (using a height mode) for the row
     based on the label node in a certain column, or calculate different Y-offsets (using
     a height mode) for each label node in the row (even if that breaks baseline
     alignment).  All of this seems like overkill, and needs a use-case.
*/
@interface HLTableLayoutManager : NSObject <HLLayoutManager, NSCopying, NSCoding>

/// @name Creating a Table Layout Manager

/**
 Initializes a default-configuration table layout manager, featuring: an infinite count of
 columns per row; rows and columns that are sized to fit their largest nodes; and
 center-alignment of nodes in cells.
*/
- (instancetype)init;

/**
 Initializes the layout manager for a table layout where all columns and rows are sized to
 fit their largest nodes, and all nodes are center-aligned in their cells.
*/
- (instancetype)initWithColumnCount:(NSUInteger)columnCount;

/**
 Initializes the layout manager for a custom table layout.
*/
- (instancetype)initWithColumnCount:(NSUInteger)columnCount
                       columnWidths:(NSArray *)columnWidths
                 columnAnchorPoints:(NSArray *)columnAnchorPoints
                         rowHeights:(NSArray *)rowHeights;

/// @name Performing a Layout

/**
 Set the positions of all passed nodes according to the layout-affecting parameters.

 The order of the passed nodes determines position in the table: rows are filled left to
 right starting with the top row.  A cell is skipped if the corresponding element in the
 array is not a kind of `SKNode` class.  (It is suggested to pass `[NSNull null]` or
 `[SKNode node]` to intentionally leave cells empty.)

 This method must always be called explicitly to realize layout changes.  On one hand,
 it's annoying to have to remember to call it; on the other hand, it allows the owner
 efficiently to make multiple changes (e.g. remove a node, insert another node, change the
 `constrainedSize`, etc) and re-layout only exactly once.
*/
- (void)layout:(NSArray *)nodes;

/**
 Layout and (optionally) return calculated final column widths and row heights.

 See `layout:` for details.

 Also see "Accessing Last-Layout State" notes in this class and in `HLLayoutManager`.
*/
- (void)layout:(NSArray *)nodes getColumnWidths:(NSArray * __autoreleasing *)columnWidths rowHeights:(NSArray * __autoreleasing *)rowHeights;

/// @name Getting and Setting Table Geometry

/**
 The anchor point used for the table during layout, in scene unit coordinate space.

 For example, if the `anchorPoint` is `(0.0, 0.0)`, the table will be positioned above and
 to the right of the `tablePosition`.  If the `anchorPoint` is `(0.5, 0.5)`, the table
 will be centered on the `tablePosition`.

 Default value is `(0.5, 0.5)`.
*/
@property (nonatomic, assign) CGPoint anchorPoint;

/**
 A conceptual position used for the table during layout, in scene point coordinate space.

 For example, if the `tablePosition` is `(10.0, 0.0)`, all nodes laid out will have ten
 points added to their `position.x`.

 Default value is `(0.0, 0.0)`.
*/
@property (nonatomic, assign) CGPoint tablePosition;

/**
 The number of columns in the table, or `0` for infinite.

 Default value is `0`.
*/
@property (nonatomic, assign) NSUInteger columnCount;

/**
 Specifies the total width and height of the table when it contains "fill" columns and
 rows.

 See notes on `columnWidths` and `rowHeights` properties.  If there are no fill columns or
 rows, this size will be ignored.  If the constrained size (in a particular dimension) is
 not large enough to hold all the non-fill rows or columns, plus the `tableBorder` and
 cell separators, the width or height of all fill rows or columns will be set to zero, and
 the total size of the table (see `size` property) will be larger than the constrained
 size.

 Default value is `CGSizeZero`.
*/
@property (nonatomic, assign) CGSize constrainedSize;

/**
 An array of `CGFloat`s specifying the widths of table columns.

 Columns in the table without corresponding widths in the array will be sized according to
 the last column width in the array.  If the array is `nil` or empty, all columns will be
 fit-sized to their nodes (as with special value `0.0` below).

 Sizes may be specified as fixed, fit, or fill:

 - A positive width means "fixed": the column is sized to that number of points.

 - A zero width means "fit": the column is sized to fit the widest node in the column.
   The width of a node is determined by `HLLayoutManagerGetNodeWidth()`; see that function
   for details.

 - A negative width means means "fill": the column is allocated a portion of the available
   constrained width of the table.  Furthermore, the available space is shared among fill
   cells proportionally to their fill cell widths.  For example, if colummn widths are `[
   -2, -1, -2 ]`, the middle column will get half as much space as the outer columns.

 ("Positive" means greater than `HLTableLayoutManagerEpsilon`; "negative" means less than
 negative `HLTableLayoutManagerEpsilon`; "zero" otherwise.)

 For example, say the constrained width of the table is `100` for three columns.  If the
 `tableBorder` is `1` and the `columnSeparator` is `2`, that leaves `95` for the columns.
 The first column is specified with a fixed width of `35`, leaving `60` for the two
 remaining columns, which have widths specified as `-1.0` and `-2.0`, resulting in actual
 column widths of `20` and `40`, respectively.
*/
@property (nonatomic, strong) NSArray *columnWidths;

/**
 An array of CGFloats specifying the heights of table rows.

 Rows in the table without corresponding heights in the array will be sized according to
 the last row height in the array.  If the array is `nil` or empty, all rows will be
 fit-sized to their nodes.

 Sizes may be specified the same way as `columnWidths`; see notes there.
*/
@property (nonatomic, strong) NSArray *rowHeights;

/**
 The anchor points used to position and align nodes in their cells during layout,
 specified in point coordinate space.

 In order to be passed in the array, each value is a `CGPoint` wrapped in an `NSValue`,
 for example:

     layoutManager.columnAnchorPoints = @[ [NSValue valueWithCGPoint:CGPointMake(0.0f, 1.0f)] ];

 When performing a layout, the table layout manager allocates a cell (of a certain size)
 for each node.  The node is then positioned in that cell primarily according to the
 column anchor point.  Anchor `0.0` is the left edge or bottom edge of the cell; anchor
 point `1.0` is the right or top edge; anchor `0.5` is the center.

 Columns in the table without corresponding anchor points in the array will be anchored
 according to the last anchor point in the array.  If the array is `nil` or empty, all
 nodes will be positioned in the center of their allocated cell (as with anchor point
 `0.5`).

 Usually the column anchor point corresponds directly to the anchor point of sprite nodes
 or alignment modes of label nodes that will be laid out in the columns.  For instance, if
 a label has a horizontal alignment mode of `SKLabelHorizontalAlignmentModeRight`, then
 its column anchor point X value will probably be `1.0`.  It's worth noting, though, that
 the layout manager ignores the current anchor points or alignments of the nodes during
 layout.

 Note that vertically aligning label nodes can be a challenge when mixing them with sprite
 nodes.  See "Aligning Labels in a Table" in the header notes; in particular, use
 `rowLabelOffsetYs` to adjust the baseline of label nodes in the row relative to sprites.
*/
@property (nonatomic, strong) NSArray *columnAnchorPoints;

/**
 The Y-offsets used for each row to adjust the position of label nodes in their cells
 during layout, specified in point coordinate space.

 In order to be passed in an array, each value is passed as a wrapped `NSNumber` double
 that will be cast to a `CGFloat`.

 When performing a layout, the table layout manager allocates a cell (of a certain size)
 for each node.  All nodes are positioned in that cell using the column anchor point, but
 additionally, for label nodes, this Y-offset is added.

 This can help with vertical alignment of labels with respect to sprite nodes in the same
 row.  See "Aligning Labels in a Table" in the header notes for more details, and for use
 cases.

 Rows in the table without corresponding offsets in the array will be offset according to
 the last offset in the array.  If the array is `nil` or empty, no offsets will be
 applied.
*/
@property (nonatomic, strong) NSArray *rowLabelOffsetYs;

/**
 The distance (reserved by `layout:`) between each edge of the table and the nearest cell
 edge.

 Default value is `0.0`.
*/
@property (nonatomic, assign) CGFloat tableBorder;

/**
 The distance (reserved by `layout:`) between adjacent columns.

 Default value is `0.0`.
*/
@property (nonatomic, assign) CGFloat columnSeparator;

/**
 The distance (reserved by `layout:`) between adjacent rows.

 Default value is `0.0`.
*/
@property (nonatomic, assign) CGFloat rowSeparator;

/// @name Accessing Last-Layout State

/**
 Returns the calculated size of the table at the last layout.

 The size is derived from the layout-affecting parameters and last-laid-out nodes.
*/
@property (nonatomic, readonly) CGSize size;

/**
 Returns the number of rows in the table at the last layout.

 The row count is derived from the `columnCount` and the number of nodes laid out at the
 last `layout:`.
*/
@property (nonatomic, readonly) NSUInteger rowCount;

@end
