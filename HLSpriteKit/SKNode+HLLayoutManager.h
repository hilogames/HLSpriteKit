//
//  SKNode+HLLayoutManager.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/27/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLLayoutManager.h"

@interface SKNode (HLLayoutManager)

/// @name Getting and Setting the Layout Manager

/**
 Returns the layout manager set by `hlSetLayoutManager:`, if any.
*/
- (id <HLLayoutManager>)hlLayoutManager;

/**
 Attaches a layout manager to (or detaches one from) this node.

 Presumably it will be used to lay out (some of) the node's children, either by using the
 layout manager directly or by calling `hlLayoutChildren`.

 If the layout manager is the same object as the node, then the pointer to `self` is not
 explicitly retained (but will be returned by `hlLayoutManager`).
 
 Pass `nil` to unset the layout manager (if any).
*/
- (void)hlSetLayoutManager:(id <HLLayoutManager>)layoutManager;

/// @name Laying Out Children Nodes

/**
 Lays out the node's children.

 Convenience method for getting the `hlLayoutManager` and, if it exists, invoking its
 `layout` method on the node's children.  It is not considered an error if the layout
 manager or children don't exist.
*/
- (void)hlLayoutChildren;

@end
