//
//  SKNode+HLAction.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 1/9/2017.
//  Copyright (c) 2017 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLAction.h"

/**
 A class category for attaching an action runner to a node.
*/
@interface SKNode (HLAction)

/// @name Managing the Action Runner

/**
 Returns the action runner attached to the node, or `nil` for none.
*/
- (HLActionRunner *)hlActionRunner;

/**
 Returns `YES` if there is an action runner attached to this node.
*/
- (BOOL)hlHasActionRunner;

/**
 Attaches an action runner to, or removes an action runner from, this node.
*/
- (void)hlSetActionRunner:(HLActionRunner *)actionRunner;

/**
 Updates the attached action runner, if any, passing this node and the node's `speed` as
 parameters to the update.

 For a discussion of node `speed` and how it affects the update, see `[HLActionRunner
 update:node:speed:]`.
*/
- (void)hlActionRunnerUpdate:(NSTimeInterval)incrementalTime;

/// @name Managing Actions

/**
 Adds an action to the attached action runner, if any.
*/
- (void)hlRunAction:(HLAction *)action withKey:(NSString *)key;

/**
 Returns `YES` if this node has an attached action runner with actions.
*/
- (BOOL)hlHasActions;

/**
 Returns an action for the passed key, or `nil` if there is no action runner attached to
 this node or if the action doesn't exist.
*/
- (HLAction *)hlActionForKey:(NSString *)key;

/**
 Removes an action for the passed key.

 Does nothing if the action is not found, or if the node does not have an attached action
 runner.
*/
- (void)hlRemoveActionForKey:(NSString *)key;

/**
 Removes all actions, if any, from the attached action runner, if any.
*/
- (void)hlRemoveAllActions;

@end
