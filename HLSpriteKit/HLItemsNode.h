//
//  HLItemsNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/5/15.
//  Copyright (c) 2015 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLComponentNode.h"

@class HLItemNode;

/**
 `HLItemsNode` maintains a collection of `HLItemNode` children nodes, and provides an
 interface for common interactions.

 It is intended to be a base class (through composition) for classes which contain a
 group of buttons or icons or tools for a more-specific purpose; it provides common
 functionality.  "Inheritance by composition" is recommended: Some of the interface is
 best protected from the end-user, and certain things like `zPosition` management are much
 easier when this class is its own component of an owner.
 */
@interface HLItemsNode : HLComponentNode <NSCopying, NSCoding>

/// @name Creating an Items Node

/**
 Initializes an items node with its items.

 After initialization, it is typical for the items to be configured with content (see
 `setContent:`) and laid out by the derived class.

 @param itemCount The number of items that will be maintained by the items node.

 @param itemPrototypeNode An `HLItemNode` which will be copied to create each item node.
                          If `nil`, a generic `HLItemNode` will be used.
 */
- (instancetype)initWithItemCount:(int)itemCount itemPrototype:(HLItemNode *)itemPrototypeNode;

/// @name Getting Items

/**
 Returns the items (of type `HLItemNode`) maintained by this items node.

 This is essentially a protected interface to the items nodes, to be used by derived
 classes for positioning and configuration of the items, if necessary; see `HLItemNode`.
 */
@property (nonatomic, readonly) NSArray *itemNodes;

/// @name Setting Item Content

/**
 Convenience method for calling `[HLItemNode setContent:]` on the item nodes, in order,
 with a content node from the passed array.

 The items node was created with a fixed number of items, and only that many content nodes
 may be set; any extras passed in the array will be ignored.  An item may be left without
 content by passing `[NSNull null]` in the appropriate position in the array.

 See `HLItemNode` for notes on how content is managed by the container item node, and for
 notes on `HLItemNode` configuration (for example, what `anchorPoint` to expect).
 */
- (void)setContent:(NSArray *)contentNodes;

/// @name Managing Item Geometry

/**
 Convenience method for calling `[SKNode containsPoint]` on the item nodes, in order, and
 returning the index of the first item that claims to contain the point, or `-1` for none.

 The `[SKNode containsPoint]` method might not, of course, be appropriate for some
 applications.  Compare `itemClosestToPoint` for an alternative.

 @param location The location, in the coordinate system of this node.

 @return The index of the first item that contains the passed location, or `-1` for none.
 */
- (int)itemContainingPoint:(CGPoint)location;

/**
 Convenience method for calling `[HLItemNode distanceToPoint:]` on the item nodes and
 returning the index of the item closest to the passed location, within the passed maximum
 distance, or `-1` for none.

 @param location The location, in the coordinate system of this node.

 @param maximumDistance A distance limiting how the distance of the closest item in order
                        to be returned.  If passed less than or equal to zero, no maximum
                        will be enforced.

 @param closestDistance If not `nil`, and if the method returns a closest node, will be
                        set with the distance of the closest node.

 @return The index of the item closest to the passed location, within the passed maximum
         distance, or `-1` for none.
 */
- (int)itemClosestToPoint:(CGPoint)location
          maximumDistance:(CGFloat)maximumDistance
          closestDistance:(CGFloat *)closestDistance;

/// @name Configuring Item State

/**
 Convenience method for returning the index of the item last selected; see
 `setSelectionForItem:`.

 Returns -1 if no item is currently selected.
*/
- (int)selectionItem;

/**
 Convenience method for setting the highlight state of a single item.

 Sets highlight `YES` for the passed item, and sets highlight `NO` for the previously
 selected item, if any, and if the index is valid.
*/
- (void)setSelectionForItem:(int)itemIndex;

/**
 Convenience method for setting the highlight state of a single item with animation.

 Animates highlight `YES` for the passed item, and sets highlight `NO` (with no animation)
 for the previously-selected item, if any.
*/
- (void)setSelectionForItem:(int)itemIndex
                 blinkCount:(int)blinkCount
          halfCycleDuration:(NSTimeInterval)halfCycleDuration
                 completion:(void(^)(void))completion;

/**
 Convenience method for clearing the last selection.
 
 Sets highlight `NO` for the previously-selected item, if any.
 */
- (void)clearSelection;

/**
 Convenience method for clearing the last selection with animation.
 
 Sets highlight `NO` for the previously-selected item, if any, with animation.
 */
- (void)clearSelectionBlinkCount:(int)blinkCount
               halfCycleDuration:(NSTimeInterval)halfCycleDuration
                      completion:(void(^)(void))completion;

@end
