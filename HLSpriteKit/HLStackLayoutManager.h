//
//  HLStackLayoutManager.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 1/30/18.
//  Copyright (c) 2018 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLLayoutManager.h"
#import "SKLabelNode+HLLabelNodeAdditions.h"

FOUNDATION_EXPORT const CGFloat HLStackLayoutManagerEpsilon;

/**
 The direction for the stack.
*/
typedef NS_ENUM(NSInteger, HLStackLayoutManagerStackDirection) {
  /**
   Nodes are stacked rightwards from the starting point.
  */
  HLStackLayoutManagerStackRight,
  /**
   Nodes are stacked leftwards from the starting point.
  */
  HLStackLayoutManagerStackLeft,
  /**
   Nodes are stacked upwards from the starting point.
  */
  HLStackLayoutManagerStackUp,
  /**
   Nodes are stacked downwards from the starting point.
  */
  HLStackLayoutManagerStackDown,
};

/**
 Provides functionality to lay out (set positions of) nodes in a straight line.

 The stack layout manager concerns itself primarily with node position in a single
 dimension according to the stacking direction (see `stackDirection`).  See "Stacks are
 One-Dimensional", below, for discussion about positioning nodes in the non-stacking
 dimension.

 Nodes are laid out by the stack in conceptual cells, with sizing and alignment options.
 By default, a stack layout manager stacks nodes rightwards in cells that fit each node.
 See below for more uses.

 This manager may be attached to an `SKNode` using `[SKNode+HLLayoutManager
 hlSetLayoutManager]`.

 ### Examples

 #### A sentence composed of multiple label nodes.

 One of them displays a numeric variable:

     sentenceNodes = @[ [SKLabelNode labelNodeWithText:@"You have"],
                        pickleCountNode,
                        [SKLabelNode labelNodeWithText:@"pickles remaining."] ];

 Layout the sentence so that each label fits exactly, with a small separator:

     layoutManager.cellSeparator = 4.0f;
     [layoutManager layout:sentenceNodes];

 Result:

     You have 3 pickles remaining.

 Layout the sentence with a fixed-sized space for the pickle count (so that the layout
 doesn't change when the pickle count changes):

     layoutManager.cellLengths = @[ @(0.0), @(30.0), @(0.0) ];
     [layoutManager layout:sentenceNodes];

 Result:

     You have  3  pickles remaining.

 Fit the whole sentence into a specific width.  The pickle count cell will fill any extra
 space.  Also, right-align the pickle count in its cell:

     layoutManager.constrainedLength = 200.0f;
     layoutManager.cellLengths = @[ @(0.0), @(-1.0), @(0.0) ];
     pickleCountNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
     layoutManager.cellAnchorPoints = @[ @(0.5), @(1.0), @(0.5) ];
     [layoutManager layout:sentenceNodes];

 Result:

     You have      3 pickles remaining.

 #### A button bar.

 Suppose the buttons are in two groups, with two spacers separating groups:

     buttonNodes = @[ [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(20.0f, 20.0f)],
                      [SKNode node],
                      [SKSpriteNode spriteNodeWithColor:[SKColor orangeColor] size:CGSizeMake(20.0f, 20.0f)],
                      [SKNode node],
                      [SKSpriteNode spriteNodeWithColor:[SKColor yellowColor] size:CGSizeMake(20.0f, 20.0f)],
                      [SKSpriteNode spriteNodeWithColor:[SKColor greenColor] size:CGSizeMake(20.0f, 20.0f)],
                      [SKSpriteNode spriteNodeWithColor:[SKColor blueColor] size:CGSizeMake(20.0f, 20.0f)] ];

 Layout the button bar left-to-right and centered at the node parent origin:

     [layoutManager layout:buttonNodes];

 Layout the button bar in the top-right corner of the interface.  The buttons will still
 be laid out left-to-right, but we can position the stack using a top-right anchor point:

     layoutManager.stackPosition = CGPointMake(screenRight, screenTop);
     layoutManager.anchorPoint = CGPointMake(1.0f, 1.0f);
     [layoutManager layout:buttonNodes];

 Layout the buttons in the same corner, but vertically along the right edge (rather than
 horizontally along the top):

     layoutManager.stackDirection = HLStackLayoutManagerStackDown;
     [layoutManager layout:buttonNodes];

 Allocate fixed-sized cells for the spacer nodes.  The second spacer is twice as big as
 the first:

     // note: Final value in list is used for all remaining cells.
     layoutManager.cellLengths = @[ @(0.0), @(10.0), @(0.0), @(20.0), @(0.0) ];
     [layoutManager layout:buttonNodes];

 Expand the button bar into a constrained length.  The spacer nodes are allocated the
 extra space, but the second spacer will always be twice as big as the first:

     layoutManager.constrainedLength = 200.0f;
     layoutManager.cellLengths = @[ @(0.0), @(-1.0), @(0.0), @(-2.0), @(0.0) ];
     [layoutManager layout:buttonNodes];

 ### Stacks are One-Dimensional

 Stacks are one-dimensional.  In particular:

   - The stack itself only reports its `stackLength` and not a standard-orientation
     `size`.

   - In the stacking dimension (determiend by `stackDirection`), nodes are positioned and
     measured and aligned; in the non-stacking dimension, nodes are positioned simply by a
     constant (from `stackPosition`).

   - (Well, okay, and also maybe the `cellLabelOffsetY` affects the non-stacking
     dimension; see "Aligning Labels in a Stack", below.)

 This simplifies but limits the stack.  For example:

   - By `SKLabelNode` default, a horizontal stack of label nodes will be baseline-aligned,
     and a vertical stack center-aligned.

   - By `SKSpriteNode` default, a stack of sprite nodes will be center-aligned.

 Anything else requires tweaking anchor points or alignments or positions (in the
 non-stacking dimension) on each node.  In the worst case, you might need to loop through
 the nodes after every layout in order to tweak them (in the non-stacking dimension).

 If you find yourself needing awareness of the non-stacking dimension, please let the
 developer know!  I am looking for use cases.

 ### Aligning Labels in a Stack

 #### Vertical Alignment in a Horizontal Stack

 Say you have a horizontal stack of label nodes.  How do you vertically align the text?

   - The Y position of each node will be set to `stackPosition.y`.

   - Therefore, it's easy to vertically align a horizontal stack of label nodes using the
     `verticalAlignmentMode` property of the labels: baseline, top, center, or bottom.
     Baseline alignment is typical.

 Things get more complicated, however, in the following situations:

   1. When you want to layout a mixed stack of label nodes and sprite nodes.

                  +-----+             +----+ +-----+
          Player  |#####|  Abilities  | /\ | | --> |
                  +-----+             +----+ +-----+

   2. When you want to layout a stack of label nodes inside an enclosing box.

          +----------------------------------+
          |  Wave   3  of   10     Gold  15  |
          +----------------------------------+

 In these cases, baseline alignment for the label nodes is still typical.  The question
 is: Where should the baseline go relative to the sprite nodes?

 Well, the answer is: "Anywhere you want it to go."  Commonly, though, the goal is to
 **visually center** the text with the boxes.  In that case the answer is usually: "Down a
 few points."

 Probably you should not adjust sprite node anchor points in order to achive visual
 centering.  The Y-offset required to visually-center a label is related to the label's
 font geometry and size, and is unrelated to the heights of the nearby sprites or
 enclosing box.  In other words, it's a Y-offset in point coordinate space and not an
 anchor in unit coordinate space.

 Instead, calculate the offset for different kinds of visual centering using
 `baselineOffsetYFromVisualCenterForHeightMode:fontName:fontSize:` from
 `SKLabelNode+HLLabelNodeAdditions`.

 Then use `cellLabelOffsetY` to configure the offset on the stack.  It will automatically
 be applied to label nodes, and not sprite nodes.

 Comments on usage:

   - The primary use-case for `cellLabelOffsetY` is for (vertical) visual centering of
     baseline-aligned label nodes in a horizontal stack.

   - It is assumed (though not enforced) that all label nodes will be using baseline
     alignment.

   - If labels in the stack have different fonts or font sizes, their calculated
     visual-centering Y-offsets will be different.  But baseline-alignment is the
     priority, and so the table only allows a single offset calculated for the entire
     stack.  Use the "typical" font size to calculate the shared offset, or use an
     average, or forget the offset and go back to tweaking anchor points.  (The helper
     `baselineInsetYFromBottomForHeightMode:fontName:fontSize:` deals with unit coordinate
     space insets, not offsets, and might be able to provide a good anchor point value.)

 #### Vertical Alignment in a Vertical Stack

 With a vertical stack including label nodes, the goal is often the same as with a
 horizontal stack: It's nice to vertically visually center labels in their cells as
 compared to sprite nodes in the stack or in the background.

 The `cellLabelOffsetY` can again be used to selectively offset all label baselines in the
 stack (while leaving any sprites as they are).

 But as with the horizontal stack, only a single offset can be specified.  If the vertical
 stack has labels with different fonts or font sizes, then using the same offset for all
 of them might not be what you want.

 There is currently no implemented solution for this problem.  Plase let the developer
 know if you are experiencing it, and if so, how you would like it fixed!
*/
@interface HLStackLayoutManager : NSObject <HLLayoutManager, NSCopying, NSCoding>

/// @name Creating a Stack Layout Manager

/**
 Initializes a default-configuration stack layout manager, for a rightwards stack layout
 of nodes where all nodes are stacked according to their size.
*/
- (instancetype)init;

/**
 Initializes the layout manager with parameters for a stack layout of nodes where all
 nodes are stacked according to their size.
*/
- (instancetype)initWithStackDirection:(HLStackLayoutManagerStackDirection)stackDirection;

/**
 Initializes the layout manager with parameters for a customized stack layout of nodes.
*/
- (instancetype)initWithStackDirection:(HLStackLayoutManagerStackDirection)stackDirection
                           cellLengths:(NSArray *)cellLengths;

/**
 Initializes the layout manager with parameters for a customized stack layout of nodes.
*/
- (instancetype)initWithStackDirection:(HLStackLayoutManagerStackDirection)stackDirection
                           cellLengths:(NSArray *)cellLengths
                      cellAnchorPoints:(NSArray *)cellAnchorPoints;

/// @name Performing a Layout

/**
 Set the positions of all passed nodes according to the layout-affecting parameters.

 Nodes are stacked in array order according to `stackDirection`.  A stack cell is skipped
 if the corresponding element in the passed array is not a kind of `SKNode` class.  (It is
 suggested to pass `[NSNull null]` or `[SKNode node]` to intentionally leave cells empty.)

 This method must always be called explicitly to realize layout changes.  On one hand,
 it's annoying to have to remember to call it; on the other hand, it allows the owner
 efficiently to make multiple changes (e.g. change anchor points, change lengths, etc) and
 re-layout only exactly once.
*/
- (void)layout:(NSArray *)nodes;

/// @name Getting and Setting Stack Geometry

/**
 The direction of the stack.

 See `HLStackLayoutManagerStackDirection` for details.
*/
@property (nonatomic, assign) HLStackLayoutManagerStackDirection stackDirection;

/**
 The anchor point used for the stack during layout, in scene unit coordinate space.

 Since the stack is only aware of one dimension, the anchor point is actually an anchor
 float.

 For example, if the `anchorPoint` is `0.0`, the stack will be positioned to the right of
 the `stackPosition`.  If the `anchorPoint` is `0.5`, the stack will be centered on the
 `stackPosition`.

 Default value is `0.5`.
*/
@property (nonatomic, assign) CGFloat anchorPoint;

/**
 A conceptual position used for the stack during layout, in scene point coordinate space.

 For example, if the `stackPosition` is `(10.0, 0.0)`, all nodes laid out will have ten
 points added to their `position.x`.

 Default value is `(0.0, 0.0)`.
*/
@property (nonatomic, assign) CGPoint stackPosition;

/**
 Specifies the total length of the stack when it contains "fill" cells.

 See notes on `cellLengths` property.  If there are no fill cells, this length will be
 ignored.  If the constrained length is not large enough to hold all the non-fill cells,
 plus the `stackBorder` and `cellSeparator`, the length of all fill cells will be set to
 zero, and the total length of the stack (see `length` property) will be larger than the
 constrained length.
*/
@property (nonatomic, assign) CGFloat constrainedLength;

/**
 An array of `CGFloat` (wrapped in `NSNumber` doubles) specifying the lengths of cells in
 the stack.

 Cells in the stack without corresponding lengths in the array will be sized according to
 the last length in the array.  If the array is `nil` or empty, all cells will be
 fit-sized to their nodes (as with special value zero, described below).

 Sizes may be specified as fixed, fit, or fill:

 - A positive length means "fixed": the cell is sized to that number of points.

 - A zero length means "fit": the cell is sized to fit the node it contains.  The official
   size of a node is calculated by `HLLayoutManagerGetNodeSize()`; see that function for
   details.

 - A negative length means "fill": the cell is allocated a portion of the available
   constrained length of the stack.  Furthermore, the available space is shared among fill
   cells proportionally to their (negative) lengths.  For example, if the cell lengths are
   `[ -2, -1, -2 ]`, the middle cell will get half as much space as the outer cells.

 ("Positive" means greater than `HLStackLayoutManagerEpsilon`; "negative" means less than
 negative `HLStackLayoutManagerEpsilon`; "zero" otherwise.)

 Examples:

 - `[ 0.0 ]` stacks all nodes according to their sizes.

 - `[ 50.0 ]` stacks nodes in cells of size `50.0` points (regardless of node size).

 - `[ -1.0 ]` spreads all cells out evenly across `constrainedLength`.

 - `[ 35.0, -1.0, -2.0 ]` gives `35.0` points to the first cell, and splits the remaining
   length of `constrainedLength` between the next two cells, giving twice as much to the
   last.  If, for instance, `constrainedLength` is `100`, `stackBorder` is `1`, and
   `cellSeparator` is `2`, that leaves `95` for the cells.  The first cell uses `35`
   points of that, and the remaining `60` is split so that the second cell gets `20` and
   the third cell gets `40`.
*/
@property (nonatomic, strong) NSArray *cellLengths;

/**
 The anchor points used to position and align nodes in their cells during layout,
 specified in unit coordinate space.

 Since the stack is only aware of one dimension, each cell has only one anchor point
 value, corresponding to the stacking dimension (either X or Y).  In order to be passed in
 an array, values are passed as wrapped `NSNumber` doubles that will be cast to `CGFloat`.

 When performing a layout, the stack layout manager allocates a cell (of a certain length)
 for each node.  The node is then positioned in that cell according to the cell anchor
 point.  For horizontal stacking, anchor point `0.0` is the left edge of the cell and
 `1.0` is the right edge; for vertical stacking, anchor point `0.0` is the bottom edge of
 the cell and `1.0` is the top edge; for both, anchor point `0.5` is the center of the
 cell.

 Cells in the stack without corresponding anchor points in the array will be anchored
 according to the last anchor point in the array.  If the array is `nil` or empty, all
 nodes will be positioned in the center of their allocated cell (as with anchor point
 `0.5`).

 Usually the cell anchor point corresponds directly to the anchor point of sprite nodes or
 alignment modes of label nodes that will be laid out in the cells.  For instance, if a
 label has a horizontal alignment mode of `SKLabelHorizontalAlignmentModeRight`, then in a
 horizontal stack its cell anchor point will probably be `1.0`.  It's worth noting,
 though, that the layout manager ignores the current anchor points or alignments of the
 nodes during layout.

 Note that vertically aligning label nodes in either vertical or horizontal stacks can be
 a challenge when mixing them with sprite nodes.  See "Aligning Labels in a Stack" in the
 header notes.
*/
@property (nonatomic, strong) NSArray *cellAnchorPoints;

/**
 A Y-offset used to adjust the position of all label nodes in the stack during layout,
 specified in point coordinate space.

 When performing a layout, the table layout manager allocates a cell (of a certain size)
 for each node.  All nodes are positioned in that cell using the column anchor point, but
 additionally, for label nodes, this Y-offset is added.

 This can help with vertical alignment of labels with respect to sprite nodes in the same
 stack.  See "Aligning Labels in a Stack" in the header notes for more details, and for
 use cases.

 Default value is `0.0`.
*/
@property (nonatomic, assign) CGFloat cellLabelOffsetY;

/**
 The distance (reserved by `layout:`) between each edge of the stack and the nearest cell
 edge.

 Default value is `0.0`.
*/
@property (nonatomic, assign) CGFloat stackBorder;

/**
 The distance (reserved by `layout:`) between adjacent cells.

 Default value is `0.0`.
*/
@property (nonatomic, assign) CGFloat cellSeparator;

/// @name Accessing Last-Layout State

/**
 Returns the calculated length of the stack at the last layout.

 The length is derived from the layout-affecting parameters and last-laid-out nodes.
*/
@property (nonatomic, readonly) CGFloat length;

@end

/**
 Convenience method for finding the index of the node whose cell contains the passed
 point, for nodes that have been laid out by an `HLStackLayoutManager`.

 Since the stack is only aware of one dimension, the point is a single value corresponding
 to the stacking dimension (either X or Y).

 Returns `NSNotFound` if no such node is found.

 The algorithm uses binary search in the nodes list (assuming it is ordered by position in
 the stacking dimension), and calculates cell length in the same way it is calculated in
 `HLStackLayoutManager` (which involves a few array lookups and `NSValue` conversions).
 The non-stacking dimension is not considered.  The stacking direction could be inferred,
 but the stacking dimension cannot.  The cell separator is not considered to be part of
 the node's cell; it is inferred from the current node position.
*/
NSUInteger HLStackLayoutManagerCellContainingPoint(NSArray *nodes,
                                                   CGFloat point,
                                                   HLStackLayoutManagerStackDirection stackDirection,
                                                   NSArray *cellLengths,
                                                   NSArray *cellAnchorPoints,
                                                   CGFloat cellLabelOffsetY);
