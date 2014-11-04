//
//  SKNode+HLLayoutManager.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/27/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLLayoutManager.h"

@interface SKNode (HLLayoutManager)

/**
 * Returns the layout manager set by hlSetLayoutManager, if any.
 */
- (id <HLLayoutManager>)hlLayoutManager;

/**
 * Attaches a layout manager to this node; presumably it will be used to layout (some of)
 * the node's children, either by using the layout manager directly or by calling
 * hlLayoutChildren.
 *
 * If the layout manager is the same object as the node, then the pointer to self is not
 * explicitly retained (but will be returned by hlLayoutManager).
 */
- (void)hlSetLayoutManager:(id <HLLayoutManager>)layoutManager;

/**
 * Lays out the nodes children.  Convenience method for getting the hlLayoutManager and,
 * if it exists, invoking its layout method on the node's children.  It is not considered
 * an error if the layout manager or children don't exist.
 */
- (void)hlLayoutChildren;

@end
