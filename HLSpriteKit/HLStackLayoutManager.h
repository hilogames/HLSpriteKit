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
 Convenience method to vertically align and offset any label nodes passed in the array.

 In particular, for every `SKLabelNode`, calls the `SKLabelNode+HLLabelNodeAdditions`
 category method `alignVerticalWithAlignmentMode:heightMode:` with the relevant
 parameters, and then additionally adds `additionalOffsetY` to the label node's position.
 See the category method for details of possible vertical alignments.

 See "Aligning Labels in a Stack" in the header notes for the purpose of this method.  In
 particular, this method is intended for *vertically* aligning label nodes in a
 *horizontal* stack, which must be done after every layout.  For vertically aligning label
 nodes in a *vertical* stack, instead use `cellOffsets` before layout (perhaps with helper
 `HLStackLayoutManagerBaselineCellOffsetsFromVisualCenter()`).

 See `layout:withVerticalAlignLabelNodes:heightMode:additionalOffsetY:` to call this
 method in combination with a stack layout.
*/
void
HLStackLayoutManagerVerticalAlignLabelNodes(NSArray *nodes,
                                            SKLabelVerticalAlignmentMode alignmentMode,
                                            HLLabelHeightMode heightMode,
                                            CGFloat additionalOffsetY);

/**
 Convenience method to calculate appropriate `cellOffsets` for a vertical stack layout
 manager that wants to visually center baseline-aligned label nodes within their cells.

 In particular, for every `SKLabelNode`, calls the `SKLabelNode+HLLabelNodeAdditions`
 category method `baselineOffsetYWithVisualCenterForHeightMode:` with the relevant
 parameters.  Each resulting offset, with an additional `additionalOffsetY` is recorded
 into an array of `cellOffsets` that can be used to layout the nodes in stack layout
 manager.  (An offset of zero is recorded in the array for non-label-nodes.)

 This method assumes the label nodes will be using `SKLabelVerticalAlignmentModeBaseline`,
 but neither sets this value on the nodes nor check that it has been set.

 See "Aligning Labels in a Stack" in the header notes for the purpose of this method.  In
 particular, this method is intended for *vertically* aligning label nodes in a *vertical*
 stack.  For vertically aligning label nodes in a *horizontal* stack, instead use
 `HLStackLayoutManagerVerticalAlignLabelNodes()`, which must be called after every layout.

 Also it's worth noting that this method is overkill for stacks that contain only label
 nodes.  Again, see header notes, but the real purpose is for visual-center vertical
 alignment of label nodes mixed with sprite nodes, which is non-trivial.
*/
NSArray *
HLStackLayoutManagerBaselineCellOffsetsFromVisualCenter(NSArray *nodes,
                                                        HLLabelHeightMode heightMode,
                                                        CGFloat additionalOffsetY);

/**
 Provides functionality to lay out (set positions of) nodes in a straight line.

 The stack layout manager concerns itself primarily with node position in a single
 dimension according to the stacking direction (see `stackDirection`).  See below for
 discussion about positioning nodes in the non-stacking dimension.

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
     measured and aligned and offset; in the non-stacking dimension, nodes are positioned
     simply by a constant (from `stackPosition`).

 This simplifies but limits the stack.  For example:

   - By `SKLabelNode` default, a horizontal stack of label nodes will be baseline-aligned,
     and a vertical stack center-aligned.

   - By `SKSpriteNode` default, a stack of sprite nodes will be center-aligned.

 Anything else requires tweaking anchor points or alignments or positions (in the
 non-stacking dimension) on each node.  In the worst case, you might need to loop through
 the nodes after every layout in order to tweak them (in the non-stacking dimension).

 If you find yourself needing awareness of the non-stacking dimension, consider these
 possibilities and alternatives:

   1. Use a module helper method to do positional adjustments in the non-stacking
      dimension.  Currently there is only a single helper, that can do vertical alignment
      of label nodes in horizontal stacks.  More helpers can be added as they are proven
      useful.  Each helper also has an associated convenience `layout:*` method which
      calls the helper automatically after layout.

   2. Use a single-record `HLTableLayoutManager`.  The table interface is similar to the
      stack interface, but tables are aware of two dimensions.  Translate "cells" in the
      stack to "fields" in the table; translate "length" of the stack to "width" of the
      table (regardless of stack or table direction).  An example, side-by-side:

          stack.stackDirection = ...;              table.fieldDirection = ...;
          stack.constrainedLength = 500.0f;        table.constrainedFieldWidth = 500.0f;
          stack.cellLengths = @[ @(0), @(-1) ];    table.fieldWidths = @[ @(0), @(-1) ];

      And then, importantly, the table allows configuration in the second dimension:

          stack.cellAnchorPoints = @[ @(0.25) ];   table.fieldAnchorPoints = @[ @(0.25, ...) ];
          ...                                      table.recordHeight = @[ @(100) ];

 See "Design Notes" below for further thoughts on the topic.

 ### Aligning Labels in a Stack

 #### Vertical Alignment in a Horizontal Stack

 Say you have a horizontal stack of label nodes.  How do you vertically align the text?

   - In a horizontal stack, the Y position of each node will be set by the stack layout
     manager to `stackPosition.y`.

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

 Well, the answer is: "Anywhere you want it to go."  But there's a special case of this
 special case which nevertheless occurs frequently: Where should the baseline go relative
 to the sprite nodes **if you want the text visually centered with the boxes**?  Now the
 answer is usually: "Down a few points."

 It is not convenient to achieve this by tweaking sprite node anchor points.  The Y-offset
 required to visually-center a label is related to the label's font geometry and size, and
 is unrelated to the height of the cell or box in which the label is located.

 So instead, when visually centering labels and sprites, configure all vertical positions
 to the intended visual center axis (using `stackPosition.y`).  Then perform the layout.
 Then use a helper method to calculate and apply a Y-position offset for each label node
 (for a given kind of visual centering).  This will need to be done after every layout,
 but at least it will automatically adapt to changes in font typeface, font size, and
 visual-centering styles.

 The helper method is `HLStackLayoutManagerVerticalAlignLabelNodes()`.

 For the kind of visual centering discussed here, you'd ask it to align label nodes using
 center alignment for a certain height mode; try "ascender bias" for a sometimes-pleasing
 result:

     playerNodes = @[ [SKLabelNode labelNodeWithText:@"Player"],
                       portraitSpriteNode,
                       [SKLabelNode labelNodeWithText:@"Abilities"]
                       ability1SpriteNode,
                       ability2SpriteNode ]];

     layoutManager.stackPosition = CGPointMake(0.0f, visualCenterY);
     [layoutManager layout:playerNodes];
     HLStackLayoutManagerVerticalAlignLabelNodes(playerNodes,
                                                 SKLabelVerticalAlignmentModeCenter,
                                                 HLLabelHeightModeFontAscenderBias,
                                                 0.0f);

 To help call it after every layout, combine the last two lines together using a
 convenience form of `layout`:

     [layoutManager layout:playerNodes
        withLabelNodesVerticalAlign:SKLabelVerticalAlignmentModeCenter
                         heightMode:HLLabelHeightModeFontAscenderBias
                  additionalOffsetY:0.0f];

 The helper method provides a full set of options for vertical alignment of labels; see
 that method for details.

 #### Vertical Alignment in a Vertical Stack

 With a vertical stack including label nodes, the goal is often the same as with a
 horizontal stack: It's nice to vertically visually center labels in their cells.

 Again, the Y-offset from baseline required to visually-center a label node is a point
 value related to the label's font geometry and size and not related to the height of its
 cell.

 In a vertical stack, the vertical position of each label node can be configured with
 `cellOffsets`.  So, unlike a horizontal stack, the visual centering offset(s) can be
 calculated once and configured in the stack for all layouts.

 If the same offset should be used by all labels, which is likely, it can be calculated
 once using `baselineOffsetYFromVisualCenterForHeightMode:fontName:fontSize:` from
 `SKLabelNode+HLLabelNodeAdditions`.

 Or, if different cells need different offsets, the setup (without a helper method) looks
 more like this:

     SKLabelNode *smallLabel = [SKLabelNode labelNodeWithFontNamed:@"Courier"];
     smallLabel.fontSize = 10.0f;
     CGFloat smallOffsetY = [smallLabel baselineOffsetYWithVisualCenterForHeightMode:HLLabelHeightModeFont];

     SKSpriteNode *thumbnail = [SKSpriteNode ...];
     thumbnail.anchorPoint = CGPointMake(0.5f, 0.5f);

     SKLabelNode *bigLabel = [SKLabelNode labelNodeWithFontNamed:@"Helvetica"];
     bigLabel.fontSize = 36.0f;
     CGFloat bigOffsetY = [bigLabel baselineOffsetYWithVisualCenterForHeightMode:HLLabelHeightModeFont];

     NSArray *stackNodes = @[ smallLabel, thumbnail, bigLabel ];

     layoutManager.stackDirection = HLStackLayoutManagerStackDirectionDown;
     layoutManager.cellOffsets = @[ @(smallOffsetY), @(0.0f), @(bigOffsetY) ];
     [layoutManager layout:stackNodes];

 The module helper method `HLStackLayoutManagerBaselineCellOffsetsFromVisualCenter()` can
 calculate appropriate visual-centering `cellOffsets` for each label node in the array of
 nodes that will be laid out.  This is overkill in most situations, but might help for
 complicated layouts.

 ### Design Notes

 Problems with adding a second dimension to the stack layout manager:

   - Would need a way to specify the breadth of the stack.  "Breadth" isn't great.
     Perhaps "cross-length"?  When I think about this, I almost always decide that the
     table is doing it the right way, by using "width" to mean the direction of the
     "fields" (whether that's horizontal or vertical), and "height" to mean the direction
     of the "records".  My best attempt at a two-dimensional stack-like interface uses
     "width" as the stacking direction, by convention, matching the table metaphor.  Of
     course, then "stack" isn't quite right, because stacks in real life go up and down;
     the two-dimensional version of the stack layout manager is instead called a "strip"
     or "bar" or "line".  And the strip interface is then basically a one-record table,
     without the "field" or "record" terminology:

         Table                     Stack               Strip
         ------------------------  ------------------  -----------------------
         size [S]                                      size [S]
         tableSize [D]             stackLength         stripSize [D]

         fieldDirection            direction           direction
         recordDirection

         fieldCount
         fieldWidths               cellLengths         cellWidths
         fieldAnchorPoints [S]     cellAnchorPoints    cellAnchorPoints [S]
         fieldOffsets [S]          cellOffsets         cellOffsets [S]
         recordHeights                                 cellHeight

         constrainedTableWidth     constrainedLength   constrainedStripWidth
         constrainedTableHeight                        constrainedStripHeight

         anchorPoint [S]           anchorPoint         anchorPoint [S]
         tablePosition [S]         stackPosition [S]   stripPosition [S]
         tableBorder               stackBorder         stripBorder
         fieldSeparator            cellSeparator       cellSeparator
         rowSeparator

         [S] Each point is a two-dimensional vector with dimensions in the standard (X, Y)
             screen geometry order.

         [D] Each point is a two-dimensional vector with dimensions in the directional
             order: for tables (field, record); for strips (directional, non-directional).

     I tried instead to take "width" and "height" out from the table manager.  But I just
     couldn't find good alternate terms.

     In the stack, I like the simplification of the one-dimensional "length".  The
     implementation of a strip manager is basically the same as a one-record table.  So
     just use a one-record table.

   - Would need a way to specify cell alignment (anchor points and offsets) in the second
     dimension.  We'd need to decide whether we can use anchor points in the standard (X,
     Y) order like tables, or whether we'd use anchor points in the directional order
     (length, breadth).  The latter would probably be surprising/bad, so maybe instead
     we'd split them explicitly into two arrays, `cellLengthAnchors` and
     `cellBreadthAnchors`.  Nah; probably just do (X, Y) anchor points.  Again, this is
     what the table layout manager already does.  Similar thinking for cell offsets.

 Problems with integrating more-sophisticated alignment options into layout managers:

   - Cell alignment in the stack can be done using either anchor points (unit coordinate
     space, relative to cell size) or offsets (point coordinate space).

   - Label nodes use "alignment"; sprite nodes use "anchor point".  Both of these can be
     translated into either cell anchor points or offsets.

   - Giving the stack manager any kind of alignment options in the non-stacking dimension
     means adding awareness of the second dimension; see above.

   - Stack manager is often used for sentences, and table manager for "name: value"
     tables.  Could provide configuration options to both that would apply only to label
     nodes, if any.  For stacks call the options `cellLabelHeightMode` and
     `cellLabelVerticalAlignment`; for tables call them `field*`.  But they would be
     specific to certain nodes, certain directions, and certain fonts.  Could spinoff
     special classes: `HLSentenceLayoutManager` and `HLTextInfoTableLayoutManager`.  So
     bloatey.

   - Could allow a special negative value for all anchor points or offsets in all layout
     managers, whether one-dimensional or two-.  It would mean "automatic", and for sprite
     nodes it would set the cell anchor point to the sprite node's anchor point.  For
     label nodes it would set cell alignment based on the horizontal- or
     vertical-alignment of the label node, as appropriate.  But really I want to offer
     "visual centering" with `HLLabelHeightMode` options.  Maybe -1, -2, -3 could all be
     different height modes?  Er, for label nodes?  Seems like bloat.  Plus one more small
     point: Maybe we'd like "automatic" alignment to set the node alignment based on the
     layout manager, rather than the other way around.

   - So yeah.  Use helper functions, not extra configuration.

   - But the big regret: That for visual centering of text in a horizontal stack, the
     helper function might need to be called for every layout.
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

/**
 Convenience method to perform layout and then vertically align and offset any label nodes
 in the stack using the passed alignment options.

 In other words, this method does the same thing as a call to `layout` followed by a call
 to `HLStackLayoutManagerVerticalAlignLabelNodes()`.

 See "Aligning Labels in a Stack" in the header notes for the purpose of this method.  In
 particular, this method is intended for *vertically* aligning label nodes in a
 *horizontal* stack, which must be done after every layout.  For vertically aligning label
 nodes in a *vertical* stack, instead use `cellOffsets` before layout (perhaps with helper
 `HLStackLayoutManagerBaselineCellOffsetsFromVisualCenter()`).

 See `layout:` for general information about layouts.
*/
- (void)layout:(NSArray *)nodes
 withLabelNodesVerticalAlign:(SKLabelVerticalAlignmentMode)alignmentMode
                  heightMode:(HLLabelHeightMode)heightMode
           additionalOffsetY:(CGFloat)additionalOffsetY;

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
 an array, each value is passed as a wrapped `NSNumber` double that will be cast to a
 `CGFloat`.

 When performing a layout, the stack layout manager allocates a cell (of a certain length)
 for each node.  The node is then positioned in that cell according to the cell anchor
 point and cell offset.  For horizontal stacking, anchor point `0.0` is the left edge of
 the cell and `1.0` is the right edge; for vertical stacking, anchor point `0.0` is the
 bottom edge of the cell and `1.0` is the top edge; for both, anchor point `0.5` is the
 center of the cell.

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

 Use `cellOffsets` to position nodes in their cells using point coordinate space.

 Note that vertically aligning label nodes in either vertical or horizontal stacks can be
 a challenge when mixing them with sprite nodes.  See "Aligning Labels in a Stack" in the
 header notes.
*/
@property (nonatomic, strong) NSArray *cellAnchorPoints;

/**
 The offsets used to position and align nodes in their cells during layout, specified in
 point coordinate space.

 Since the stack is only aware of one dimension, each cell has only one offset value,
 corresponding to the stacking dimension (either X or Y).  In order to be passed in an
 array, each value is passed as a wrapped `NSNumber` double that will be cast to a
 `CGFloat`.

 When performing a layout, the stack layout manager allocates a cell (of a certain length)
 for each node.  The node is then positioned in that cell according to the cell anchor
 point and cell offset.  Offsets use point coordinate space: For horizontal stacking, the
 offset increases to the right in the X dimension; for vertical stacking, the offset
 increases upwards in the Y dimension.

 Cells in the stack without corresponding offsets in the array will be offset according to
 the last offset in the array.  If the array is `nil` or empty, nodes will not be offset
 from `stackPosition`.

 Use `cellAnchorPoints` to position nodes in their cells using unit coordinate space.

 Note that vertically aligning label nodes in either vertical or horizontal stacks can be
 a challenge when mixing them with sprite nodes.  See "Aligning Labels in a Stack" in the
 header notes.
*/
@property (nonatomic, strong) NSArray *cellOffsets;

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
