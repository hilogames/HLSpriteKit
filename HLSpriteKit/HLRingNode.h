//
//  HLRingNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/5/15.
//  Copyright (c) 2015 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLComponentNode.h"
#import "HLGestureTarget.h"

@protocol HLRingNodeDelegate;

/**
 `HLRingNode` extends (through composition) an `HLItemsNode` with the following features:

 - Items are arranged in a ring centered around the ring node's position.

 - Items are transparent, and are displayed over a background image and beneath a frame
   image.  This can give the illusion of cropping as long as the frame is big enough to
   cover the item content nodes.

 - Because the items themselves are transparent, item content should use
   `HLItemContentNode` in order to indicate various item states (like enabled and
   highlight), if desired.

 - Basic gesture handling support is provided.

 ## Common Gesture Handling Configurations

 - Set this node as its own gesture target (using `[SKNode+HLGestureTarget
   hlSetGestureTarget]`) to get simple delegation and/or a callback for taps.  See
   `HLRingNodeDelegate` for delegation and the `itemTappedBlock` property for setting a
   callback block.

 - Set a custom gesture target to recognize and respond to other gestures.  (Convert touch
   locations to this node's coordinate system and call `itemAtPoint` as desired.)

 - Leave the gesture target unset for no gesture handling.
 */
@interface HLRingNode : HLComponentNode <NSCopying, NSCoding, HLGestureTarget>

/// @name Creating a Ring Node

/**
 Initializes a ring node with a fixed number of items.

 After initialization, a ring node should be configured with content (see `setContent:`)
 and a layout (see `setLayout*`).
 */
- (instancetype)initWithItemCount:(int)itemCount;

/// @name Managing Interaction

/**
 The delegate invoked on interaction (when this node is its own gesture handler).

 Unless this ring node is its own gesture handler, this delegate will not be called.
 See "Common Gesture Handling Configurations".
 */
@property (nonatomic, weak) id <HLRingNodeDelegate> delegate;

/**
 A callback invoked when an item is tapped (when this node is its own gesture handler).

 The index of the tapped item is passed as an argument to the callback.

 A tap is considered to be on an item if it is within the distance defined by
 `itemAtPointDistanceMax`.

 Unless this item node is its own gesture handler, this callback will not be invoked.
 See "Common Gesture Handling Configurations".

 Beware retain cycles when using the callback to invoke a method in the owner.  As a safer
 alternative, use the item node's delegation interface; see `setDelegate:`.
 */
@property (nonatomic, copy) void (^itemTappedBlock)(int itemIndex);

/// @name Managing Geometry and Layout

/**
 Sets the layout of the ring node with items at specified angular coordinates.

 note: Currently the layout-affecting parameters are not properties, and so can't be set
 individually, which helps avoid the problem where layout is redone multiple times as
 each parameter is adjusted individually.

 Layout can be set with or without content set.

 Raises an exception if the number of thetas provided doesn't match the number of items
 in the ring.

 @param radius The distance betwen the origin (position) of the ring node and the center
               of each of the items.

 @param thetasRadians The angular coordinates (represented by NSValue CGFloats) of each
                      item (measured in radians, where 0 points right, and increasing
                      counter-clockwise).
 */
- (void)setLayoutWithRadius:(CGFloat)radius
                     thetas:(NSArray *)thetasRadians;

/**
 Sets the layout of the ring node with items spread regularly around the ring from a
 starting angular coordinate.

 note: Currently the layout-affecting parameters are not properties, and so can't be set
 individually, which helps avoid the problem where layout is redone multiple times as
 each parameter is adjusted individually.

 Layout can be set with or without content set.

 @param radius The distance betwen the origin (position) of the ring node and the center
               of each of the items.

 @param initialThetaRadians The angular coordinate of the first item on the ring (measured in
                            radians, where 0 points right, and increasing counter-clockwise).
 */
- (void)setLayoutWithRadius:(CGFloat)radius
               initialTheta:(CGFloat)initialThetaRadians;

/**
 Sets the layout of the ring node with items spaced out incrementally from a starting
 angular coordinate.

 note: Currently the layout-affecting parameters are not properties, and so can't be set
 individually, which helps avoid the problem where layout is redone multiple times as
 each parameter is adjusted individually.

 Layout can be set with or without content set.

 @param radius The distance betwen the origin (position) of the ring node and the center
               of each of the items.

 @param initialThetaRadians The angular coordinate of the first item on the ring (measured in
                            radians, where 0 points right, and increasing counter-clockwise).

 @param thetaIncrementRadians The angular distance between successive items on the ring
                              (measured in radians, where positive values indicate the
                              counter-clockwise direction).
 */
- (void)setLayoutWithRadius:(CGFloat)radius
               initialTheta:(CGFloat)initialThetaRadians
             thetaIncrement:(CGFloat)thetaIncrementRadians;

/**
 Returns the item index of the item at the passed location, or `-1` for none.

 A location is considered to be on an item if it is within the distance defined by
 `itemAtPointDistanceMax`.

 The location is expected to be in the coordinate system of this node.
 */
- (int)itemAtPoint:(CGPoint)location;

/**
 The distance maximum used in `itemAtPoint` for testing whether a location is "at" or
 "on" a certain item.

 Default value 42.0.
 */
@property (nonatomic, assign) CGFloat itemAtPointDistanceMax;

/// @name Getting and Setting Content

/**
 Sets content nodes in the items of the ring.

 The ring was created with a fixed number of items, and only that many content nodes may
 be set; any extras will be ignored.  An item may be left without content by passing
 `[NSNull null]` in the appropriate position in the array.

 The item node that holds each content node has `anchorPoint` `(0.5, 0.5)`.

 Any `SKNode` descendant may be used as content, but any content node which conforms to
 `HLItemContentNode` can customize its behavior and/or appearance for certain ring node
 functions (for example, setting enabled or highlight); see `HLItemContentNode` for
 details.
*/
- (void)setContent:(NSArray *)contentNodes;

/**
 Sets a single content node in an item of the ring node, or unsets it if passed `nil`.

 See notes on `setContent:`.  Throws an exception if the item index is out of bounds.
*/
- (void)setContent:(SKNode *)contentNode forItem:(int)itemIndex;

/**
 Returns the content node assigned to an item by `setContent:` or `setContent:forItem:`.

 Returns `nil` if the item was left without content.  Throws an exception if the item
 index is out of bounds..
*/
- (SKNode *)contentForItem:(int)itemIndex;

/// @name Configuring Appearance

/**
 A node displayed below all items and content.
 */
@property (nonatomic, strong) SKNode *backgroundNode;

/**
 A node displayed above all items and content.
 */
@property (nonatomic, strong) SKNode *frameNode;

/// @name Managing Ring Item State

/**
 Returns a boolean indicating whether an item is enabled.

 See `[HLItemNode enabled]` for details.

 Throws an exception if the item index is out of bounds.
*/
- (BOOL)enabledForItem:(int)itemIndex;

/**
 Sets the enabled state of an item.

 See `[HLItemNode setEnabled:]` for details.

 Throws an exception if the item index is out of bounds.
*/
- (void)setEnabled:(BOOL)enabled forItem:(int)itemIndex;

/**
 Returns a boolean indicating the current highlight state of an item.

 See `[HLItemNode highlight]` for details.

 Throws an exception if the item index is out of bounds.
*/
- (BOOL)highlightForItem:(int)itemIndex;

/**
 Sets the highlight state of an item.

 See `[HLItemNode setHighlight:]` for details.

 Throws an exception if the item index is out of bounds.
*/
- (void)setHighlight:(BOOL)highlight forItem:(int)itemIndex;

/**
 Sets the highlight state of an item with animation.

 See `[HLItemNode setHighlight:blinkCount:halfCycleDuration:completion:]` for details.
*/
- (void)setHighlight:(BOOL)finalHighlight
           forItem:(int)itemIndex
          blinkCount:(int)blinkCount
   halfCycleDuration:(NSTimeInterval)halfCycleDuration
          completion:(void(^)(void))completion;

/**
 Convenience method for returning the index of the item last selected; see
 `setSelectionForItem:`.

 Returns -1 if no item is currently selected.

 See `[HLItemsNode selectionItem]` for details.
*/
- (int)selectionItem;

/**
 Convenience method for setting the highlight state of a single item.

 Sets highlight `YES` for the passed item, and sets highlight `NO` for the previously
 selected item (if any).

 See `[HLItemsNode setSelectionForItem:]` for details.
*/
- (void)setSelectionForItem:(int)itemIndex;

/**
 Convenience method for setting the highlight state of a single item with animation.

 Animates highlight `YES` for the passed item, and sets highlight `NO` (with no
 animation) for the previously-selected item (if any).

 See `[HLItemsNode setSelectionForItem:blinkCount:halfCycleDuration:completion:]` for details.
*/
- (void)setSelectionForItem:(int)itemIndex
                   blinkCount:(int)blinkCount
            halfCycleDuration:(NSTimeInterval)halfCycleDuration
                   completion:(void(^)(void))completion;

/**
 Convenience method for clearing the highlight state of the last selected item.

 Clears the highlight of the last-selected item, if any.

 See `[HLItemsNode clearSelection]` for details.
*/
- (void)clearSelection;

/**
 Convenience method for clearing the highlight state of the last selected item with animation.

 Clears the highlight of the last-selected item, if any, with animation.

 See `[HLItemsNode clearSelectionBlinkCount:halfCycleDuration:completion:]` for details.
*/
- (void)clearSelectionBlinkCount:(int)blinkCount
               halfCycleDuration:(NSTimeInterval)halfCycleDuration
                      completion:(void(^)(void))completion;

@end

/**
 A delegate for `HLRingNode`.

 The delegate is (currently) concerned mostly with handling user interaction.  It's worth
 noting that the `HLRingNode` only receives gestures if it is configured as its own
 gesture target (using `[SKNode+HLGestureTarget hlSetGestureTarget]`).
 */
@protocol HLRingNodeDelegate <NSObject>

/// @name Handling User Interaction

/**
 Called when the user taps an item in the ring.
 */
- (void)ringNode:(HLRingNode *)ringNode didTapItem:(int)itemIndex;

@end
