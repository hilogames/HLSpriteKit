//
//  HLOutlineLayoutManager.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 7/9/15.
//  Copyright (c) 2015 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLLayoutManager.h"

FOUNDATION_EXPORT const CGFloat HLOutlineLayoutManagerEpsilon;

/**
 Provides functionality to lay out (set positions of) nodes in an outline.  This manager
 may be attached to an `SKNode` using `[SKNode+HLLayoutManager hlSetLayoutManager]`.

 As a vertical list, the outline does not know about its own width, or the widths of its
 nodes.  It sets node positions in the X dimension using simple fixed-size indents.
 Similarly, the outline layout manager doesn't use X anchor points for either itself or
 its nodes.

 ### Aligning Labels in an Outline

 An outline of label nodes typically uses baseline alignment on all labels.  When the
 baselines are evenly spaced, then the text looks evenly spaced.

 Things get more complicated, however, in the following situations:

   1. When the outline contains both label nodes and sprite nodes.

   2. When the outline uses more than one font or font size.

 #### When the outline contains both label nodes and sprite nodes.

 If sprites are positioned by their centers and labels by their baselines, the labels will
 probably look like they are floating too high.  It's tricky to get them both visually
 centered in their lines (while maintaining baseline alignment).

 Visually-centering labels usually means shifting them down a few points, based on font
 and font size; see `baselineOffsetYFromVisualCenterForHeightMode:fontName:fontSize:`.

 In general, then: Calculate a Y-offset using that method and configure
 `levelLabelOffsetYs` on the outline, which will offset all the label nodes (but not
 sprite nodes).

 A different offset can be calculated and specified for each level of the outline, which
 is nice if different levels use labels with different fonts or font sizes.

 #### When the outline uses more than one font or font size.

 The `levelLabelOffsetYs` specifies a single offset for each level of the outline.  This
 works well when different levels are using different fonts or font sizes.  For instance,
 a large font will probably use a (proportionally) larger offset.  (Again, the method
 `baselineOffsetYFromVisualCenterForHeightMode:fontName:fontSize:` can help calculate good
 offset values for different fonts.)

 If multiple fonts or font sizes are mixed in the same level, however, they must share a
 single offset.  Perhaps it's possible to find a "typical" offset, or an average.

 If that doesn't yield a good result, consider using `levelAnchorPointYs` instead; for
 instance, use `0.3` to place label baselines at 30% of the line height, regardless of
 font or font size.

 You can choose your own anchor point, or have one calculated for you for different kinds
 of visual centering using `baselineInsetYFromBottomForHeightMode:fontName:fontSize:`,
 again from `SKLabelNode+HLLabelNodeAdditions.h`.
*/
@interface HLOutlineLayoutManager : NSObject <HLLayoutManager, NSCopying, NSCoding>

/// @name Creating an Outline Layout Manager

/**
 Initializes an unconfigured outline layout manager.
*/
- (instancetype)init;

/**
 Initializes the layout manager with all parameters necessary for a basic outline layout
 of nodes.
*/
- (instancetype)initWithNodeLevels:(NSArray *)nodeLevels
                      levelIndents:(NSArray *)levelIndents;

/**
 Initializes the layout manager for a custom outline layout.
*/
- (instancetype)initWithNodeLevels:(NSArray *)nodeLevels
                      levelIndents:(NSArray *)levelIndents
                  levelLineHeights:(NSArray *)levelLineHeights
                levelLabelOffsetYs:(NSArray *)levelLabelOffsetYs;

/**
 Initializes the layout manager for a custom outline layout.
*/
- (instancetype)initWithNodeLevels:(NSArray *)nodeLevels
                      levelIndents:(NSArray *)levelIndents
                  levelLineHeights:(NSArray *)levelLineHeights
                levelAnchorPointYs:(NSArray *)levelAnchorPointYs;

/// @name Performing a Layout

/**
 Set the positions of all passed nodes according to the layout-affecting parameters.

 For layout to have an effect: `nodeLevels` must be set for all nodes to be positioned;
 and `levelIndents` must have at least one element.

 An outline positions its nodes in a vertical list.  Each node is assigned an outline
 level which determines how far it is indented in the horizontal direction.  Other
 geometry options like line height can be specified for each outline level.

 As a vertical list, the outline does not know about its own width, or the widths of its
 nodes.  Therefore it does not know anything about X anchor points, either.  Node X
 positions are set starting at `outlinePosition.x` and indented at each outline level by
 the corresponding value in `levelIndents`.

 Some configurations of an outline layout manager only make sense for a fixed number of
 nodes (see, for example, `setNodeLevels:`).  In that case, only as many nodes will be
 laid out as the configuration can support.

 This method must always be called explicitly to realize layout changes.  On one hand,
 it's annoying to have to remember to call it; on the other hand, it allows the owner
 efficiently to make multiple changes and re-layout only exactly once.
*/
- (void)layout:(NSArray *)nodes;

/**
 Layout with animation.

 See `layout:` for details.
*/
- (void)layout:(NSArray *)nodes animatedDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay;

/// @name Getting and Setting Outline Geometry

/**
 The anchor point Y-value used for the outline during layout.

 For example, if the `anchorPoint` is `0.0`, the outline will be positioned above the
 `outlinePosition`.  If the `anchorPoint` is `0.5`, the outline will be vertically
 centered on the `outlinePosition`.

 Default value is `0.5`.
*/
@property (nonatomic, assign) CGFloat anchorPointY;

/**
 A conceptual position used for the outline during layout, in scene point coordinate
 space.

 For example, if the `outlinePosition` is `(10.0, 0.0)`, all nodes laid out will have ten
 points added to their `position.x`.

 Default value is `(0.0, 0.0)`.
*/
@property (nonatomic, assign) CGPoint outlinePosition;

/**
 An array of `NSUInteger` (wrapped in `NSNumber`) specifying the outline level to be used
 for each node during layout.

 The first level is level `0`.

 Each node must have an explicit level.  Any nodes passed to `layout` that do not have
 corresponding levels here will not be positioned.
*/
@property (nonatomic, strong) NSArray *nodeLevels;

/**
 The horizontal indents used at each level of the outline (starting from level zero).

 In order to be passed as an array, values are passed as wrapped `NSNumber` doubles that
 will be cast to `CGFloat`.

 During layout, each node at a certain outline level will be positioned horizontally using
 the corresponding value from the array.  Any level which does not have a corresponding
 indent will use the last value in the array.

 Indents are relative to the indent of the previous level, and so they have a cumulative
 effect on a node.  For instance, if the level indents are:

     outlineLayoutManager.levelIndents = @[ @0.0f, @20.0f, @10.0f ];

 ...then a node at level 3 will have its X position indented from `outlinePosition.x` by
 `40`, which is the sum of the indents of levels 0 through 3 (respectively, `0`, `20`,
 `10`, and `10`).
*/
@property (nonatomic, strong) NSArray *levelIndents;

/**
 The line heights used at each level of the outline (starting from level zero).

 In order to be passed as an array, values are passed as wrapped `NSNumber` doubles that
 will be cast to `CGFloat`.

 Any level which does not have a corresponding height will use the last value in the
 array.  If the array is `nil` or empty, all lines will be fit-sized to their nodes (as
 with special value zero, described below).

 During layout, the layout manager allocates a line (of a certain height) for each node.
 Heights may be specified as either "fixed" or "fit":

 - A positive height means "fixed": the line is sized to that number of points.

 - A zero height means "fit": the line is sized to fit the node it contains.  The official
   size of a node is calculated by `HLLayoutManagerGetNodeHeight()`; see that function for
   details.

 ("Positive" means greater than `HLOutlineLayoutManagerEpsilon`; "zero" otherwise.)

 There are three heights to consider at each level when configuring vertical spacing in an
 outline.  The line height is the space reserved for a single node at the level.  The
 "before-separator" (see `levelLineBeforeSeparators`) is the space reserved before the
 node at that level, but only if it is not the first node in the outline.  The
 "after-separator" (see `levelLineAfterSeparators`) is the space reserved after the node
 at that level, but only if it is not the last node in the outline.  Visually:

    Example Node I (at Level 0)          ]-- "line height" at level 0
                                         ]-- "after separator" at level 0
      Example Node A (at Level 1)        ]-- the sum of all three heights at level 1
      Example Node B (at Level 1)
      Example Node C (at Level 1)
                                         ]-- "before separator" at level 0
    Example Node II (at Level 0)
                                         ]-- "after separator" at level 0
                                         ]-- "before separator" at level 0
    Example Node III (at Level 0)
*/
@property (nonatomic, strong) NSArray *levelLineHeights;

/**
 The anchor point Y-values used to position and align nodes in their lines at each level
 of the outline (starting from level zero), specified in unit coordinate space.

 In order to be passed as an array, values are passed as wrapped `NSNumber` doubles that
 will be cast to `CGFloat`.

 During layout, the layout manager allocates a line (of a certain height) for each node.
 The node is then positioned vertically in that line according to the anchor point.
 Anchor point Y `0.0` is the bottom edge of the line; `1.0` is the top edge; `0.5` is the
 center.

 Any level which does not have a corresponding height will use the last value in the
 array.  If the array is `nil` or empty, all nodes will be positioned in the center of
 their allocated line (as with anchor point `0.5`).

 Usually the line anchor point corresponds directly to the anchor point of sprite nodes or
 alignment modes of label nodes that will be laid out in the cells.  For instance, if a
 label has a vertical alignment mode of `SKLabelVerticalAlignmentModeCenter`, then its
 line anchor point will probably be `0.5`.  It's worth noting, though, that the layout
 manager ignores the current anchor points or alignments of the nodes during layout.

 Note that vertically aligning label nodes can be a challenge when mixing them with sprite
 nodes.  See "Aligning Labels in an Outline" in the header notes.
*/
@property (nonatomic, strong) NSArray *levelAnchorPointYs;

/**
 The Y-offsets used to adjust the position of all label nodes in their lines at each level
 of the outline (starting from level zero), specified in point coordinate space.

 In order to be passed as an array, values are passed as wrapped `NSNumber` doubles that
 will be cast to `CGFloat`.

 During layout, the layout manager allocates a line (of a certain height) for each node.
 All nodes are positioned in that line by their level anchor point (see
 `levelAnchorPointYs`), but additionally, for label nodes, this Y-offset is added.

 This can help with visual centering of labels with different fonts or font sizes at
 different levels of the outline, or with respect to sprite nodes.  See "Aligning Labels
 in a Outline" in the header notes for more details, and for use cases.

 Any level which does not have a corresponding Y-offset will use the last value in the
 array.  If the array is `nil` or empty, no offsets are added.
*/
@property (nonatomic, strong) NSArray *levelLabelOffsetYs;

/**
 The distance separating each line from the previous line in the outline, specified by
 level (starting from level zero).

 In order to be passed as an array, values are passed as wrapped `NSNumber` doubles that
 will be cast to `CGFloat`.

 During layout, the layout manager allocates a line (of a certain height) for each node.
 The line is spaced out from the previous line according to a value in this array.  All
 nodes of a certain level use the same before-separator value.

 Any level which does not have a corresponding separator in the array will use the last
 value in the array.  If the array is `nil` or empty, all before-separators will be zero.

 The very first line in the outline does not have a previous line, so it ignores its
 before-separator.

 The difference between before- and after-separators is only apparent when the separators
 are different for different levels.  If the before-separator is nonzero for level 0 but
 zero for level 1, and no after-separator is set, the result will be something like this:

     First Unit
       introduction
       development
       conclusion

     Second Unit
       introduction
       development
       conclusion

 If both after-separator and before-separator are nonzero for level 0 and zero for level
 1, then the result will look more like this:

     First Unit

       introduction
       development
       conclusion

     Second Unit

       introduction
       development
       conclusion
*/
@property (nonatomic, strong) NSArray *levelLineBeforeSeparators;

/**
 The distance separating each line from the next line in the outline, specified by level
 (starting from level zero).

 In order to be passed as an array, values are passed as wrapped `NSNumber` doubles that
 will be cast to `CGFloat`.

 During layout, the layout manager allocates a line (of a certain height) for each node.
 The line is spaced out from the next line according to a value in this array.  All nodes
 of a certain level use the same after-separator value.

 Any level which does not have a corresponding separator in the array will use the last
 value in the array.  If the array is `nil` or empty, all before-separators will be zero.

 The very last line in the outline does not have a next line, so it ignores its
 after-separator.

 See `levelLineBeforeSeparators` for an illustration of the difference between before- and
 after-separators.
*/
@property (nonatomic, strong) NSArray *levelLineAfterSeparators;

/// @name Accessing Last-Layout State

/**
 Returns the calculated height of the outline at the last layout.

 The height is derived from the layout-affecting parameters and the last-laid-out nodes.
*/
@property (nonatomic, readonly) CGFloat height;

@end

/**
 Convenience method for finding the index of the node whose line contains the passed Y
 position, for nodes that have been laid out by an `HLOutlineLayoutManager`.

 Returns `NSNotFound` if no such line is found.

 The algorithm uses binary search in the nodes list (assuming it is ordered by descending
 Y position), and calculates line height in the same way it is calculated in
 `HLOutlineLayoutManager` (which involves a few array lookups and `NSValue` conversions).
 X position is not considered.  Separators (both "before" and "after") are not considered
 to be part of the node's line; they do not need to be passed because they are inferred
 from current node position.
*/
NSUInteger HLOutlineLayoutManagerLineContainingPointY(NSArray *nodes,
                                                      CGFloat pointY,
                                                      NSArray *nodeLevels,
                                                      NSArray *levelLineHeights,
                                                      NSArray *levelAnchorPointYs,
                                                      NSArray *levelLabelOffsetYs);
