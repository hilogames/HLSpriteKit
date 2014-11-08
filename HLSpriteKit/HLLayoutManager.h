//
//  HLLayoutManager.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/27/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

/**
 * An HLLayoutManager lays out nodes (typically the children nodes of a parent) by setting
 * their positions.
 *
 * Three common patterns for handling node child layout:
 *
 *  1) The children of a node are positioned within it by the owner of the parent
 *     node, often the SKScene, which considers itself to control the entire
 *     hierarchy.
 *
 *  2) The children of a custom node subclass are positioned by the node subclass,
 *     which considers itself to control its children.  By convention, the owner
 *     of the parent node, usually the SKScene, interacts only with the node subclass,
 *     configuring it according to its public interface.
 *
 *  3) Nodes are positioned by a third party, neither the parent nor the owner.
 *
 * The layout manager takes the third approach, with the following features:
 *
 *  . Parameters are encapsulated with the layout code in an object.  However,
 *    the layout manager is a protocol, not a class hierarchy, so that any object
 *    can be a layout manager.  This, in turn, allows reuse of the layout manager
 *    for patterns (1) and (2), above: the SKScene can instantiate a layout manager
 *    to position anything in its node hierarchy, or a custom node subclass can
 *    be its own layout manager.
 *
 *  . A layout manager can be attached to any SKNode through the SKNode+HLLayoutManager
 *    category (which merely sets the layout manager in the node's userData, and
 *    returns it on demand).  Since layout managers support copying and coding,
 *    they will remain attached to the node even through duplication and archiving.
 */
@protocol HLLayoutManager <NSObject, NSCopying, NSCoding>

/**
 * Lays out the passed nodes by setting their positions.
 *
 * Notes for adopters:
 *
 *  . Decide whether layout is only performed on-demand (when the owner calls layout)
 *    or whether it happens automatically on the modification of the layout manager's
 *    properties; document for the owner.  The advantage of the former is that multiple
 *    property changes can be made efficiently; the advantage of the latter is that
 *    the owner does not have to make explicit calls.
 */
- (void)layout:(NSArray *)nodes;

@end
