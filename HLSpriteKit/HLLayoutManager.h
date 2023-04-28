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
 The two starting points for thinking about last-layout state are these:

 . Layout managers are functor-like: They do a single layout, and all their properties are
   parameters of that layout.  They are not expected to be stateful in terms of the work
   done during layout.

 . However, the layout manager is an expert of the last layout performed, and it is a
   natural place to query information about it, especially aggregate information.  For
   instance, it is almost always immediately useful and meaningful to ask a layout
   manager: "What was the overall size (or what were the bounds) of your last layout?"

 So far there is not a single unified interface among the layout managers for accesing
 last-layout state.  The design of a such a unified interface, if any is possible, has
 not fully emerged yet; different last-layout information seems suited to different kinds
 of interfaces.  For example:

 . Most of the managers retain a **small** amount of information from the last layout,
   for example `size` from `HLTableLayoutManager` or `height` from `HLOutlineLayoutManager`.
   This information is explicitly marked in a Tasks section _Accessing Last-Layout State_.

 . `HLOutlineLayoutManager` provides a global static helper function which can make
   calculations related to last-layout state (namely, finding the node that contains a
   certain point).  In this case, though, the necessary state is already present on the
   laid-out nodes themselves, and so the function takes the last-laid-out nodes (and a
   few key manager properties) as input, and needs no other persistent state.

 . `HLGridLayoutManager` does a similar kind of calculation, but it needs almost all of
   the manager properties, and none of the nodes, and so it implements its helper
   as an object method.

 . `HLTableLayoutManager` can optionally return from the `layout` method certain derived
   last-layout properties (namely, column widths and row heights).

 . `HLRingLayoutManager` could do any of the above to return calculated thetas from last-
   layout.  Really, it's a trivial calculation, and depends only on the thetas mode and
   the number of nodes laid out.  Could retain last _nodeCount and recalculate thetas
   on-demand after layout.  Could provide static class methods or global helpers which
   return hypothetical thetas given a certain node count.  Could return thetas from a
   a `layout` method.  Going with the last for now, but really, any of the above would
   work.

 Here are further thoughts about these kinds of last-layout state:

 . Keeping small last-layout state on the layout manager itself makes good sense in the
   typical use case.  Most owners need it, and it's nice for the owner not to have to
   track a separate state variable after layout.

 . Returning last-layout state separately from the `layout` method makes good sense
   because it correctly indicates that the state is associated only with that single
   layout, and not with the (mutable) current configuration of the layout manager.

   . Returning it optionally is best, so that layouts don't waste time or space
     storing layout data that won't be needed.

   . Different managers will need to track and return different state, so perhaps there
     should be a single interface, with an associated hierarchy of state objects:

       - (void)layout:(NSArray *)nodes getState:(GLLayoutState * __autoreleasing *)layoutState;

     The layout manager often calculates useful data derived from the main geometrical
     properties configured; it could store this intermediate data in the layout state
     object, and the layout state object would then be able to do sophisticated and useful
     calculations for the owner.

     Then again, perhaps that's over-engineered, and perhaps there is no need for
     polymorphism or encapsulation.  (And one more problem: Often the layout state needs
     to copy some or all of the properties of the layout manager itself in order to make
     sophisticated calculations.)  Instead, if the last-layout state is more-or-less
     plain-old-data, then each layout manager could declare similarly-named layout methods
     returning simple state potentially interesting to an owner:

       - (void)layout:(NSArray *)nodes getSize:(CGSize *)size;
       - (void)layout:(NSArray *)nodes getColumnWidths:(NSArray * __autoreleasing *)columnWidths;

 . Related to the last point about over-engineering, above: The global helper function
   approach really can help simplify things.  Last-layout state is often completely
   and efficiently represented by 1) the layout manager's properties and 2) the final
   positions of the laid-out nodes.  In that case, we don't want extra state objects
   flying around; we want reusable code which knows how to do useful calculations
   on the already-extant last-layout state information.  So: global helper function.
*/

@end

/**
 Convenience method (for layout managers) providing a standard way to calculate the required
 size of a node for layout purposes.

 In particular, some managers allow layout geometry to be specified as "automatic" based
 on the nodes laid out, but there is no one way to calculate the size of a node.  This is
 a standard, simplified way (rather than using, say, `calculateAccumulatedFrame`): If the
 node responds to `size`, then that property is used; if the node is an SKLabelNode, then
 the frame size is returned; otherwise, the size is considered to be zero.
*/
CGSize HLLayoutManagerGetNodeSize(id node);

/**
 Convenience method (for layout managers) providing a standard way to calculate the required
 width of a node for layout purposes.

 See `HLLayoutManagerGetNodeSize()`.
*/
CGFloat HLLayoutManagerGetNodeWidth(id node);

/**
 Convenience method (for layout managers) providing a standard way to calculate the required
 height of a node for layout purposes.

 See `HLLayoutManagerGetNodeSize()`.
*/
CGFloat HLLayoutManagerGetNodeHeight(id node);
