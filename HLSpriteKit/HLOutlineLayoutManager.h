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
*/
@interface HLOutlineLayoutManager : NSObject <HLLayoutManager, NSCopying, NSCoding>

/// @name Creating an Outline Layout Manager

/**
 Initializes an unconfigured outline layout manager.
*/
- (instancetype)init;

/**
 Initializes the object with all parameters necessary for a basic outline layout of nodes.
*/
- (instancetype)initWithNodeLevels:(NSArray *)nodeLevels
                      levelIndents:(NSArray *)levelIndents
                  levelNodeHeights:(NSArray *)levelNodeHeights
                levelAnchorPointYs:(NSArray *)levelAnchorPointYs;

/// @name Performing a Layout

/**
 Set the positions of all passed nodes according to the layout-affecting parameters.

 For layout to have an effect: `nodeLevels` must be set for all nodes to be positioned;
 and `levelIndents`, `levelNodeHeights`, and `levelAnchorPointYs` must have at least one
 element each.

 An outline positions its nodes in a vertical list.  Each node is assigned an outline
 level which determines how far it is indented in the horizontal direction.  Other
 geometry options, like a fixed height for each "line" (node), can be specified for each
 outline level.

 As a vertical list, the outline does not know about its own width, or the widths of its
 nodes.  Therefore it does not know anything about X anchor points, either.  Node X
 positions are set starting at `outlineOffset.x` and indented at each outline level by the
 corresponding value in `levelIndents`.

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

 For example, if the `anchorPointY` is `0.5`, the outline will be centered vertically on
 position `0.0` plus the `outlineOffset.y`.  Default value is `0.5`.
*/
@property (nonatomic, assign) CGFloat anchorPointY;

/**
 A constant offset used for the outline during layout.

 For example, if the `outlineOffset` is `(10.0, 0.0)`, all nodes laid out will have ten
 points added to their `position.x`.  Default value is `(0.0, 0.0)`.
*/
@property (nonatomic, assign) CGPoint outlineOffset;

/**
 An array of `NSUInteger` specifying the outline level to be used for each node during
 layout.

 The first level is level `0`.

 Each node must have an explicit level.  Any nodes passed to `layout` that do not have
 corresponding levels here will not be positioned.
*/
@property (nonatomic, strong) NSArray *nodeLevels;

/**
 An array of `CGFloat` specifying the horizontal indent used at each level of the outline
 (starting from level zero).

 During layout, each node at a certain outline level will be positioned using the
 corresponding value from the array.  Any level which does not have a corresponding indent
 will use the last value in the array.

 Indents are relative to the indent of the previous level, and so they have a cumulative
 effect on a node.  For instance, if the level indents are:

     outlineLayoutManager.levelIndents = @[ @0.0f, @20.0f, @10.0f ];

 ...then a node at level 3 will have its X position indented from `outlineOffset.x` by
 `40`, which is the sum of the indents of levels 0 through 3 (respectively, `0`, `20`,
 `10`, and `10`).
*/
@property (nonatomic, strong) NSArray *levelIndents;

/**
 An array of `CGFloat` specifying the basic node height used at each level of the outline
 (starting from level zero).

 During layout, each node at a certain outline level will be positioned using the
 corresponding value from the array.  Any level which does not have a corresponding node
 height will use the last value in the array.

 A special height may be specified as follows:

 - A height of `0.0` (that is, a value that has a difference from `0.0` less than
   `HLOutlineLayoutNodeEpsilon`) means the layout manager should attempt to position the
   node according to its natural height.  The height of a node is determined by
   `HLLayoutManagerGetNodeHeight()`; see that function for details.

 There are three heights to consider at each level when configuring vertical spacing in an
 outline.  The node height is the space reserved for a single node at the level.  The
 "before-separator" height (see `levelSeparatorBeforeHeights`) is the space reserved
 before the node at that level, but only if it is not the first node in the outline.  The
 "after-separator" height (see `levelSeparatorAfterHeights`) is the space reserved after
 the node at that level, but only if it is not the last node in the outline.  Visually:

    Example Node I (at Level 0)          ]-- "node height" at level 0
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
@property (nonatomic, strong) NSArray *levelNodeHeights;

/**
 An array of `CGFloat` specifying the anchor point Y-value used at each level of the
 outline (starting from level zero).

 During layout, each node at a certain outline level will be positioned using the
 corresponding value from the array.  Any level which does not have a corresponding anchor
 point Y-value will use the last value in the array.

 The nodes being laid out may or may not have their own `anchorPoint` properties; if they
 do, they will be ignored by this layout manager.  (In most cases the nodes at a certain
 level should have the same anchor point Y-value as their level.)

 An example: It is common to outline text, where each node being laid out is an
 `SKLabelNode` horizontally aligned to the left and vertically aligned at the baseline.
 In such a case, it is good to use the font height (or some other related value) as the
 node height for the level, and the proportion of font descender to total font height as
 the Y anchor point for the level.  Perhaps something like this:

     outlineLayoutManager.levelNodeHeights = @[ @16.0f, @12.0f ];
     outlineLayoutManager.levelAnchorPointYs = @[ @0.25f ];
*/
@property (nonatomic, strong) NSArray *levelAnchorPointYs;

/**
 An array of `CGFloat` specifying the "before-separator" heights used at each level of the
 outline (starting from level zero).

 During layout, each node at a certain outline level will be positioned using the
 corresponding value from the array.  Any level which does not have a corresponding height
 will use the last value in the array.

 The "before-separator" height is the space reserved before the node at that level, but
 only if it is not the first node in the outline.
*/
@property (nonatomic, strong) NSArray *levelSeparatorBeforeHeights;

/**
 An array of `CGFloat` specifying the "after-separator" heights used at each level of the
 outline (starting from level zero).

 During layout, each node at a certain outline level will be positioned using the
 corresponding value from the array.  Any level which does not have a corresponding height
 will use the last value in the array.

 The "after-separator" height is the space reserved after the node at that level, but only
 if it is not the last node in the outline.
*/
@property (nonatomic, strong) NSArray *levelSeparatorAfterHeights;

/// @name Accessing Last-Layout State

/**
 Returns the calculated height of the outline at the last layout.

 The height is derived from the layout-affecting parameters and the last-laid-out nodes.
*/
@property (nonatomic, readonly) CGFloat height;

@end

/**
 Convenience method for finding the index of the node containing the passed Y position, for
 nodes that have been laid out by an `HLOutlineLayoutManager`.

 Returns `NSNotFound` if no such node is found.

 The algorithm uses binary search in the nodes list (assuming it is ordered by descending
 Y position), and calculates node height in the same way it is calculated in
 `HLOutlineLayoutManager` (which involves a few array lookups and `NSValue` conversions).
 X position is not considered.  Separators (both "before" and "after") are not considered
 to be contained by the node.
*/
NSUInteger HLOutlineLayoutManagerNodeContainingPointY(NSArray *nodes, CGFloat pointY,
                                                      NSArray *nodeLevels,
                                                      NSArray *levelNodeHeights, NSArray *levelAnchorPointYs);
