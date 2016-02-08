//
//  HLLayoutManager.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/27/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

/**
 An `HLLayoutManager` lays out nodes (typically the children nodes of a parent) by
 setting their positions.

 ## Motivation

 Three common patterns for handling child node layout:

 1. The children of a node are positioned within it by the owner of the parent node, often
    the `SKScene`, which considers itself the controller of the entire hierarchy.

 2. The children of a custom node subclass are positioned by the node subclass, which
    considers itself the controller of its children.  By convention, the owner of the
    parent node, usually the `SKScene`, interacts only with the node subclass, configuring
    it according to its public interface.

 3. Nodes are positioned by a third party, neither the parent nor the owner.

 The layout manager takes the third approach, with the following features:

 - Parameters are encapsulated with the layout code in an object.  However, the layout
   manager is a protocol, not a class hierarchy, so that any object can be a layout
   manager.  This, in turn, allows reuse of the layout manager for patterns (1) and (2),
   above: the `SKScene` can instantiate a layout manager to position anything in its node
   hierarchy, or a custom node subclass can be its own layout manager.

 - A layout manager can be attached to any `SKNode` through `[SKNode+HLLayoutManager
   hlSetLayoutManager]` (which merely sets the layout manager in the node's `userData`,
   and returns it on demand).  Since layout managers support copying and coding, they will
   remain attached to the node even through duplication and archiving.
*/
@protocol HLLayoutManager <NSObject, NSCopying, NSCoding>

/// @name Performing a Layout

/**
 Lays out the passed nodes by setting their positions.

 Notes for adopters:

 - Decide whether layout is only performed on-demand (when the owner calls `layout`) or
   whether it happens automatically on the modification of the layout manager's
   properties; document for the owner.  The advantage of the former is that multiple
   property changes can be made efficiently; the advantage of the latter is that the owner
   does not have to make explicit calls.
*/
- (void)layout:(NSArray *)nodes;

/// @name Accessing Last-Layout State

/**
 Many thoughts about accessing the last-layout state, but so far resulting in no interface.
 Here are the thoughts:

 . Layout managers are functor-like: They do a single layout, and all their properties are
   parameters of that layout.  They are not expected to be stateful.

 . However, the layout manager is an expert of the last layout performed, and it is a
   natural place to query information about it, especially aggregate information.  For
   instance, it is almost always immediately useful and meaningful to ask a layout
   manager: "What is the overall size (or what are the bounds) of your last layout?"

 . Last-layout state could be optionally returned by the `layout` method.  This makes
   sense for two reasons: 1) If the caller didn't request it, then the state wouldn't have
   to be stored; 2) Returning it from a single call to `layout` indicates quite correctly
   that it is state associated only with that single layout, and not with the (mutable)
   current configuration of the layout manager.  The last-layout state is different for
   different layout managers, and so it would make sense to encapsulate it in an object
   with both data and code, for example which could answer a question like, "What node
   contains the following point?"  The layout manager often calculates useful data derived
   from the main geometrical properties configured; it could store this intermediate data
   in the layout state object, and the layout state object would then be able to do
   sophisticated and useful calculations for the owner.  A few drawbacks, though: 1) A
   separate object to track; 2) A separate object hierarchy to develop; 3) The state
   object might need to copy many or all of the configuration properties of the original
   layout manager; 4) All in all, seems like too much engineering.

 . So meanwhile, the layout managers typically *do* track last-layout state like `size` or
   `height`, and just keep them on the layout manager itself.  Nice to at least put them
   into a section like these comments: "Accessing Last-Layout State".

 . I wanted to make a `nodeContainingPoint:` method for `HLOutlineLayoutManager`, which
   involves remembering node y-positions (sometimes automatic) at layout time and then
   doing a binary search.  But keeping track of those positions is best to do in an
   NSArray (because of things like copying and encoding), and then the caller might want
   to customize the search with concepts of nearness or what to do in the X dimension, and
   really the positions don't need to be stored in a separate array because we can do a
   binary search in the parent node's children property (which will be sorted by the
   layout manager), and so on.  All of this suggested that I needed a global static helper
   method which takes a list of children that have been laid out by an outline layout
   manager and does a binary search, with options.  No need for a custom
   HLOutlineLayoutState class just for that; it might even be useful for other layout
   managers, too.
*/

@end

/**
 Convenience method providing a standard way to calculate the required size of a node for
 layout purposes.

 In particular, some managers allow layout geometry to be specified as "automatic" based
 on the nodes laid out, but there is no one way to calculate the size of a node.  This is
 a standard, simplified way (rather than using, say, `calculateAccumulatedFrame`): If the
 node responds to `size`, then that property is used; if the node is an SKLabelNode, then
 the frame size is returned; otherwise, the size is considered to be zero.
*/
CGSize HLLayoutManagerGetNodeSize(id node);

/**
 Convenience method providing a standard way to calculate the required width of a node for
 layout purposes.

 See `HLLayoutManagerGetNodeSize()`.
*/
CGFloat HLLayoutManagerGetNodeWidth(id node);

/**
 Convenience method providing a standard way to calculate the required height of a node
 for layout purposes.

 See `HLLayoutManagerGetNodeSize()`.
*/
CGFloat HLLayoutManagerGetNodeHeight(id node);
