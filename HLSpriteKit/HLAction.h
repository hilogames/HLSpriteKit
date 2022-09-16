//
//  HLAction.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 12/22/16.
//  Copyright © 2016 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

/**
 The timing mode for an action.

 It is worth noting that all current time functions are monotonically increasing from zero
 to the duration, which means time never flows backwards.
*/
typedef NS_ENUM(NSInteger, HLActionTimingMode) {
  /**
   Time flows linearly from beginning to end.
  */
  HLActionTimingLinear,
  /**
   Time starts out slow and accelerates to a quick end, according to a sine easing
   function.
  */
  HLActionTimingEaseIn,
  /**
   Time starts out quick and decelerates to a slow end, according to a sine easing
   function.
  */
  HLActionTimingEaseOut,
  /**
   Time starts out slow, accelerates through the middle, and decelerates again to a slow
   end, according to sine easing functions.
  */
  HLActionTimingEaseInEaseOut,
};

/**
 The `HLAction` system provides a stateful alternative to the `SKAction` system.

 ## Goals and Features

 ### Similarity to `SKAction`

 For example:

     #import "HLSpriteKit/HLAction.h"
     #import "HLSpriteKit/SKNode+HLAction.h"

     [_orcNode hlRunAction:[HLAction sequence:@[ [HLAction animateWithTextures:_orcDeathFrames timePerFrame:0.2],
                                                 [HLAction waitForDuration:1.0],
                                                 [HLAction fadeOutWithDuration:3.0],
                                                 [HLAction removeFromParent] ]]
                   withKey:@"orc-death"];

 ### Control of (and Responsibility for) the Runloop

 The `SKScene` evaluates actions as part of its scene-wide frame processing (immediately
 after calling the scene's `update:` method).  By contrast, `HLAction` updates must be
 done explicitly.  To continue the previous example, in the scene implementation:

      - (void)update:(NSTimeInterval)currentTime
      {
        static NSTimeInterval lastTime = 0.0;
        NSTimeInterval incrementalTime = 0.0;
        if (lastTime > 0.0) {
          incrementalTime = currentTime - lastTime;
        }
        lastTime = currentTime;

        [_orcNode hlActionRunnerUpdate:incrementalTime];
      }

 Needless to say, this is deeply annoying.

 However, it does give complete control over the runloop, which is an advantage in some
 situations:

  * ordering updates and animations

  * sanitizing a standard game clock (to deal with slow frame rates or non-atomic system
    clocks)

  * handling game paused state, or simulation speed

 ### Statefulness During Encoding and Decoding

 `HLAction` actions, in contrast to `SKAction` actions, are mutable and stateful.

 A motivating use-case for `HLAction` is to persist animation state during encoding and
 resume it on decoding.

 Suppose that whenever an orc is killed in a game, an `SKAction` sequence runs: first, the
 orc node staggers and falls by means of a texture animation; then, the orc node fades out
 slowly over three seconds; then, the orc node is removed from the scene.

 Suppose, in the middle of that death fade, the user backgrounds the app (or saves the
 game), encoding it.

 When the game is resumed (and decoded), it would be nice if the orc corpse continued
 fading.  Even better would be if it matched pixel-perfect with the screenshot taken by
 iOS during application state preservation.

 Such fidelity is difficult using the `SKAction` system.  Here are the common
 possibilities:

  * If the entire orc node is encoded using `NSCoding`, then the ongoing `SKAction`
    animation sequence will successfully encode, decode, and resume.  Unfortunately,
    though, it does not encode its progress or its original state, and so it starts over
    from the beginning of the sequence without resetting alpha.  In the example, this
    means that the partly-faded orc will hop back on its ghostly feet in order to stagger
    and fall once again.

  * If the orc node is not encoded, but instead recreated on restoration, then no
    `SKAction` animation sequence will resume.  Either the orc node will disappear, or it
    will stay around indefinitely, or the app must figure out how to preserve and restore
    the state of the animation sequence.

 `HLAction` solves this problem by representing the state of all animations in encodable
 objects only loosely coupled to a particular node.

 Continuing the example of this section, the `HLAction` sequence would be encoded as
 follows.  If the entire node is encoded, no special code is required:

     - (void)encodeWithCoder:(NSCoder *)aCoder
     {
       [super encodeWithCoder:aCoder];
       [aCoder encodeObject:_orcNode forKey:@"orcNode"];
     }

     - (instancetype)initWithCoder:(NSCoder *)aDecoder
     {
       self = [super initWithCoder:aDecoder];
       if (self) {
         // The HLActionRunner was encoded as part of the node's userData, and will resume
         // where it left off at the next call to [_orcNode hlActionRunnerUpdate:].
         _orcNode = [aDecoder decodeObjectForKey:"orcNode"];
       }
       return self;
     }

 Typically, though, the game wants to keep nodes out of the archive, and recreate them on
 decode.  In that case, you can encode and decode just the action runner:

     - (void)encodeWithCoder:(NSCoder *)aCoder
     {
       [super encodeWithCoder:aCoder];
       [aCoder encodeObject:_orcNode.hlActionRunner forKey:@"orcNodeActionRunner"];
     }

     - (instancetype)initWithCoder:(NSCoder *)aDecoder
     {
       self = [super initWithCoder:aDecoder];
       if (self) {
         // ... (after recreating _orcNode) ...
         HLActionRunner *orcNodeActionRunner = [aDecoder decodeObjectForKey:"orcNodeActionRunner"];
         if (orcNodeActionRunner) {
           [_orcNode hlSetActionRunner:orcNodeActionRunner];
         }
       }
       return self;
     }

 Sometimes it makes sense to only encode certain named actions, and intentionally discard
 the rest:

     - (void)encodeWithCoder:(NSCoder *)aCoder
     {
       [super encodeWithCoder:aCoder];
       HLAction *deathAction = [_orcNode hlActionForKey:@"orc-death"];
       if (deathAction) {
         [aCoder encodeObject:deathAction forKey:@"orcNodeDeathAction"];
       }
     }

     - (instancetype)initWithCoder:(NSCoder *)aDecoder
     {
       self = [super initWithCoder:aDecoder];
       if (self) {
         // ... (after recreating _orcNode) ...
         HLAction *deathAction = [aDecoder decodeObjectForKey:"orcNodeDeathAction"];
         if (deathAction) {
           [_orcNode hlRunAction:deathAction withKey:@"orc-death"];
         }
       }
       return self;
     }

 One last encoding-related feature: `HLAction` works around problems encoding block-based
 actions.  In particular, attempting to encode `SKAction`'s `runBlock:` or
 `customActionWithDuration:actionBlock:` leads to a runtime warning message:

    > SKAction: Run block actions can not be properly encoded, Objective-C
    > blocks do not support NSCoding.

 `HLAction` provides alternatives which encode selectors and arguments rather than blocks
 (see `HLCustomAction` and `HLPerformSelector*Action`).

 ### Loose Coupling With Node

 All the examples so far have shown an action running while "attached" to a node (using
 class category `SKNode+HLAction`).

 The actions and action runner, however, can be operated independently of the node.

 For instance, a single action can be instantiated and updated by itself:

     HLAnimateTexturesAction *summonAction = [HLAction animateWithTextures:_elfSummonFrames timePerFrame:0.2];
     ...
     [summonAction update:incrementalTime node:_elfNode];

 ...or as part of a group or sequence:

     HLGroupAction *summonActions = [HLAction group:@[ [HLAction animateWithTextures:_elfSummonFrames timePerFrame:0.2],
                                                       [HLAction fadeInWithDuration:2.0] ]];
     ...
     [summonActions update:incrementalTime node:_elfNode];

 ...or in a standalone action runner:

     HLActionRunner *elfActionRunner = [[HLActionRunner alloc] init];
     [elfActionRunner runAction:[HLAction animateWithTextures:_elfSummonFrames timePerFrame:0.2]
                        withKey:@"summon-animate"];
     [elfActionRunner runAction:[HLAction fadeInWithDuration:2.0]
                        withKey:@"summon-fade"];
     ...
     [elfActionRunner update:incrementalTime node:_elfNode];

 In fact, the actions can be used to model animation state without ever explicitly
 animating a node.  To use an action like this, pass `nil` for the node parameter during
 the update, and access the state of the action using its public interface.  To repeat the
 "single action" example from above:

     HLAnimateTexturesAction *summonAction = [HLAction animateWithTextures:_elfSummonFrames timePerFrame:0.2];
     ...
     [summonAction update:incrementalTime node:nil];
     SKTexture *currentTexture = summonAction.texture;
     for (SKSpriteNode *elfNode in _summonElfNodes) {
       elfNode.texture = currentTexture;
     }
     NSLog(@"summon %g of %g seconds elapsed", summonAction.elapsedTime, summonAction.duration);

 One complication: Many `SKAction` actions require a node.  For instance, `[SKAction
 moveTo:duration:]` needs a node to know where to move *from*.  To support
 node-independent use of this kind of action, the corresponding `HLAction` provides an
 initializer accepting the missing information:

     // use this initializer if a node will be provided during update
     HLAction *moveAction = [HLAction moveTo:destination duration:1.0];

     // use this initializer if a node will not be provided during update
     HLAction *moveAction = [HLAction moveFrom:origin to:destination duration:1.0];
     moveAction.timingMode = HLActionTimingModeEaseInEaseOut;
     ...
     [moveAction update:incrementalTime node:nil];
     CGPoint currentPosition = moveAction.position;
     NSLog(@"current position %g,%g", currentPosition.x, currentPosition.y);

 ### Extensible and Open-Source

 `HLAction` will probably never be as fully-featured as `SKAction`, but it's worth
 mentioning: It is extensible, so you can write your own custom actions by descending from
 the `HLAction` parent class, and it is open-source, so you can see how it works.

 ## Important Differences Between `HLAction` and `SKAction`

 Because `SKAction` actions are immutable, they can be created once and run multiple
 times, on the same node or on different nodes.  `HLAction` actions, on the other hand,
 are stateful, and so should not be reused.  Running a single `HLAction` in two different
 action-runners at the same time, for instance, would advance its elapsed time twice as
 fast as expected.

 ## Possibilities

 ### Modification of Action State

 `HLAction` actions are mutable, and their state is publically accessible, which suggests
 some interesting possibilities.

  * What should happen if `timingMode` is changed while an action is running?

  * Can `elapsedTime` be freely modified?

  * Can `duration` be modified while an action is running?

  * On an action like `HLMoveToAction`, can the origin or destination points be changed
    while the action is running?

 For now almost all state is marked readonly, to protect against unintended consequences
 and to simplify implementation.

 ### Backwards Time

 In the current implementation, `speed` and `incrementalTime` are both constrained to be
 non-negative.  But backwards time might be useful, and reasonable to implement.
*/
@interface HLAction : NSObject <NSCoding, NSCopying>

/// @name Creating an Action

/**
 Initializes an action with a duration.

 All subclassed actions should call this initializer.

 @param duration The duration of the action, in seconds, or zero for non-durational
                 actions like `HLRemoveFromParent`.

 @return A configured action.
*/
- (instancetype)initWithDuration:(NSTimeInterval)duration;

/// @name Updating the Action

/**
 Updates the action state; possibly modifies node state as well.

 The return value indicates whether the node should continue being updated in the future.
 In particular, if the return value is `NO`, then the action has completed, and it must
 not be updated again.  (Some actions cannot detect or enforce this restriction by
 themselves, and must rely on their caller.)

 The node is optional; the action state will be modeled independently.  One complication:
 Some `SKAction` actions require a node for initial state.  For instance, `[SKAction
 moveTo:duration:]` needs a node to know where to move *from*.  The corresponding
 `HLAction` can be updated without a node, but must have the missing information passed in
 during initialization.  Otherwise, this method will throw an exception.

 @param incrementalTime The elapsed time since the last update call.  Negative values as
                        considered the same as zero.

 @param node The node to be updated by the action, or `nil` for none.

 @return A boolean indicating if this node should continue being updated in the future
         (that is, ongoing or "not yet completed").
*/
- (BOOL)update:(NSTimeInterval)incrementalTime node:(SKNode *)node;

/// @name Controlling Durational Actions

/**
 The expected duration of the action, in seconds.

 The actual time the action takes to complete is determined by `speed`.

 For non-durational actions like `HLRemoveFromParent`, duration will be zero.
*/
@property (nonatomic, readonly) NSTimeInterval duration;

/**
 The total elapsed time of the action, in seconds.

 Elapsed time begins at zero and increases with updates.

 The incremental time passed in to an action `update:node:` is in the time frame of the
 caller.  It is transformed into the time frame of this action by properties `speed` and
 `timingMode`.

  * Say the action has speed of `2.0` and a linear time mode.  After an update of `0.1`
    incremental seconds, its `elapsedTime` will be `0.2` seconds.

  * Say the action has normal speed and a time mode of `HLActionTimeEaseIn`.  After an
    update of `0.1` incremental seconds, its `elapsedTime` will be quite a bit less than
    `0.1`, according to the cubic easing function.

When complete, `elapsedTime` won't necessarily match the action's `duration`:

  * The final `elapsedTime` will include extra time from the final update.

  * Collections like `HLSequenceAction` or `HLGroupAction` complete when their actions are
    complete, which (depending on the speeds of their sub-actions) might result in a final
    `elapsedTime` that is wildly different than the `duration`.
*/
@property (nonatomic, readonly) NSTimeInterval elapsedTime;

/**
 The timing mode of the action, in seconds.

 A timing mode affects the way that time elapses during action updates.

 See `HLActionTimingMode` for options.

 It is worth noting that all current time functions are monotonically increasing from zero
 to the duration, which means time never flows backwards.

 Also, if the elapsed time exceeds the duration (because of slow frame rates, or because
 of the time flow behavior of certain actions like `HLSequenceAction`), time will be
 considered linear for all time modes.
*/
@property (nonatomic, assign) HLActionTimingMode timingMode;

/**
 The speed of the action.

 Speed affects how fast time updated time elapses in the time frame of this action.

 If speed is zero, most actions will not change state during an update.  However, some
 non-durational actions (like `HLPerformSelector*`) will update state.

 Note that speed does not affect the `duration` property of the action, but rather the
 `elapsedTime` property of the action.
*/
@property (nonatomic, assign) CGFloat speed;

@end

/**
 A runner and manager of `HLAction` actions.

 An action runner allows adding and removing actions by key, and updating all added
 actions with a single call.

 Usually an action runner is associated with an individual node which is passed to all
 running actions.  The node is not stored on the action runner, though, but is passed in
 as needed.
*/
@interface HLActionRunner : NSObject <NSCoding, NSCopying>

/// @name Creating an Action Runner

/**
 Returns an initialized action runner.
*/
- (instancetype)init;

/// @name Updating the Actions

/**
 Calls the update method of all actions on this action runner.

 Note that the `speed` property of the node does not affect action speed.  See
 `update:node:speed:` for details.

 @param incrementalTime The elapsed time since the last update call.  Negative values as
                        considered the same as zero.

 @param node The node to be updated by the action, or `nil` for none.  (Some kinds of
             actions require a node on update.)
*/
- (void)update:(NSTimeInterval)incrementalTime node:(SKNode *)node;

/**
 Calls the update method of all actions on this action runner, modified by a speed.

 Note that the parameter affects action speed, but the `speed` property of the node does
 **not** affect action speed.  See discussion below.

 ### Discussion: Node and Action Runner Speed

 `HLAction` promotes loose coupling between node and action; importantly, the action
 runner regards the `node` parameter as optional during updates.  Therefore, the speed
 argument to the update is separated from the node argument, and the node's `speed`
 parameter is ignored.  By example: An update without a node can still have a speed:

     [_orcActionRunner update:incrementalTime node:nil speed:2.0];

 Or, if the node exists and is being passed to the update, the speed will have to be
 passed explicitly also:

     [_orcActionRunner update:incrementalTime node:orcNode speed:orcNode.speed];

 (Alternately, the `incrementalTime` parameter could be multiplied by the caller, but that
 would make things more obscure.)

 On one hand, the extra typing is annoying.  On the other hand, it allows `HLAction` to
 meet its loose-coupling goal.  It also supports a second goal, namely, to immitate
 `SKAction` as much as possible: If the action runner is updated using the class category
 `SKNode+HLAction`, then the node's speed will automatically be passed to this method.

 @param incrementalTime The elapsed time since the last update call.  Negative values as
                        considered the same as zero.

 @param node The node to be updated by the action, or `nil` for none.  (Some kinds of
             actions require a node on update.)

 @param speed A speed which will be used to modify the `incrementalTime`.  See discussion
              above.
*/
- (void)update:(NSTimeInterval)incrementalTime node:(SKNode *)node speed:(CGFloat)speed;

/// @name Adding and Removing Actions

/**
 Adds an action to the action runner.

 The action will be updated on the next `update:node:` call.
*/
- (void)runAction:(HLAction *)action withKey:(NSString *)key;

/**
 Returns `YES` if this action runner is running any actions.
*/
- (BOOL)hasActions;

/**
 Returns the action added with the passed key, or `nil` if not found.
*/
- (HLAction *)actionForKey:(NSString *)key;

/**
 Removes the action added with the passed key.

 Does nothing if the action is not found.
*/
- (void)removeActionForKey:(NSString *)key;

/**
 Removes all actions added to this action runner.
*/
- (void)removeAllActions;

@end

/**
 A collection of actions that run in parallel.
*/
@interface HLGroupAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a group action.

 @param actions An array of `HLAction` actions.

 @return An initialized group action.
*/
- (instancetype)initWithActions:(NSArray *)actions;

/// @name Accessing Action State

/**
 The `HLAction` members of this group action.

 This property is readonly; actions should not be added or removed to the group after
 initialization.
*/
@property (nonatomic, readonly) NSArray *actions;

@end

/**
 A collection of actions that run in sequence.
*/
@interface HLSequenceAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a sequence action.

 @param actions An array of `HLAction` actions.

 @return An initialized sequence action.
*/
- (instancetype)initWithActions:(NSArray *)actions;

/// @name Accessing Action State

/**
 The non-completed `HLAction` members of this sequence action.

 This property is readonly; actions should not be added or removed to the sequence after
 initialization.
*/
@property (nonatomic, readonly) NSArray *actions;

@end

/**
 An action that repeats another action.
*/
@interface HLRepeatAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates an action that repeats another action forever.

 The action to be repeated is retained strongly, and copied on each iteration immediately
 before it is run.
*/
- (instancetype)initWithAction:(HLAction *)prototypeAction;

/**
 Creates an action that repeats another action the passed number of times.

 The action to be repeated is retained strongly, and copied on each iteration immediately
 before it is run.

 If count is passed 0, the action will be repeated forever.
*/
- (instancetype)initWithAction:(HLAction *)prototypeAction count:(NSUInteger)count;

/// @name Accessing Action State

/**
 The prototype action to be repeated.

 This prototype will be copied on each iteration.
*/
@property (nonatomic, readonly) HLAction *prototypeAction;

/**
 The copy of the prototype action currently being run, or `nil` if none.
*/
@property (nonatomic, readonly) HLAction *copiedAction;

/**
 The number of times the action will be repeated, or 0 for forever.
*/
@property (nonatomic, readonly) NSUInteger count;

/**
 The number of times the action has been repeated (to completion).
*/
@property (nonatomic, readonly) NSUInteger index;

@end

/**
 An action that idles for a duration.
*/
@interface HLWaitAction : HLAction <NSCoding, NSCopying>

@end

/**
 An action that tracks a relative change in position over a duration.
*/
@interface HLMoveByAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a move-by action.
*/
- (instancetype)initWithX:(CGFloat)deltaX y:(CGFloat)deltaY duration:(NSTimeInterval)duration;

/// @name Accessing Action State

/**
 The instantaneous change in position of the move-by action (caused by the last update).

 If a node was passed to the update method, its position was offset by this delta.
*/
@property (nonatomic, readonly) CGPoint instantaneousDelta;

@end

/**
 An action that moves from one point to another over a duration.
*/
@interface HLMoveToAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a move-to action.

 When the action is first updated, it will set its origin based on the position of the
 passed node.  For this reason, the node parameter passed to the first update must be
 non-nil.  (To set the origin without a node, use `initWithOrigin:destination:duration:`.)
*/
- (instancetype)initWithDestination:(CGPoint)destination duration:(NSTimeInterval)duration;

/**
 Creates a move-to action with a designated origin.
*/
- (instancetype)initWithOrigin:(CGPoint)origin destination:(CGPoint)destination duration:(NSTimeInterval)duration;

/// @name Accessing Action State

/**
 The current position of the move-to action.

 If a node was passed to the update method, it was updated with this position.
*/
@property (nonatomic, readonly) CGPoint position;

/**
 The value of `destination` passed to the initializer.
*/
@property (nonatomic, readonly) CGPoint destination;

@end

/**
 An action that moves from a fixed point to a changable point over a duration.

 The chase action remembers its last-calculated position, and at each update it steps from
 there toward the current destination.  This behavior distinguishes it from
 `HLMoveToAction`, which would recalculate its current position if its destination were
 changed, hopping to the straight line between the origin and new destination.

 The current position of the chase action can also be set by the owner using the
 `position` property.  During update, this position will be used as the last-calculated
 position.  (When setting `position`, the node is not available, and so it will not be
 updated.  Also, as in other move actions, the current position of the node itself, if
 provided to update, is ignored.)
*/
@interface HLChaseAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a chase action.

 When the action is first updated, it will set its origin based on the position of the
 passed node.  For this reason, the node parameter passed to the first update must be
 non-nil.  (To set the origin without a node, use `initWithOrigin:destination:duration:`.)
*/
- (instancetype)initWithDestination:(CGPoint)destination duration:(NSTimeInterval)duration;

/**
 Creates a chase action with a designated origin.
*/
- (instancetype)initWithOrigin:(CGPoint)origin destination:(CGPoint)destination duration:(NSTimeInterval)duration;

/// @name Accessing Action State

/**
 The current position of the chase action.

 This value will be used by `update` to calculate the next position (chasing after the
 destination); a node passed to the update method will have its position set accordingly.
*/
@property (nonatomic, assign) CGPoint position;

/**
 The current destination of the chase action.
*/
@property (nonatomic, assign) CGPoint destination;

@end

/**
 An action that moves from a fixed point to a changable point over a duration.

 The chase action remembers its last-calculated position, and at each update it steps from
 there toward the current destination.  This behavior distinguishes it from
 `HLMoveToAction`, which would recalculate its current position if its destination were
 changed, hopping to the straight line between the origin and new destination.

 The current position of the chase action can also be set by the owner using the
 `position` property.  During update, this position will be used as the last-calculated
 position.  (When setting `position`, the node is not available, and so it will not be
 updated.  Also, as in other move actions, the current position of the node itself, if
 provided to update, is ignored.)
*/
@interface HLChaseWeakTargetAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a chase-weak-target action.

 When the action is first updated, it will set its origin based on the position of the
 passed node.  For this reason, the node parameter passed to the first update must be
 non-nil.  (To set the origin without a node, use
 `initWithOrigin:weakTarget:selector:duration:`.)

 @param destinationWeakTarget The target that will provide a destination, retained weakly
                              in order to avoid retain cycles.  (One possible cycle, when
                              the target is the parent of the child node running the
                              action: The target retains the child node; the child node
                              retains the action runner; the action runner retains the
                              action; the action retains the target.)

 @param destinationSelector The selector that will provide a destination.  It must take no
                            parameters and return a `CGPoint`.

 @param duration The duration of the action, in seconds.
*/
- (instancetype)initWithWeakTarget:(id)destinationWeakTarget selector:(SEL)destinationSelector duration:(NSTimeInterval)duration;

/**
 Creates a chase-weak-target action with a designated origin.
*/
- (instancetype)initWithOrigin:(CGPoint)origin weakTarget:(id)destinationWeakTarget selector:(SEL)destinationSelector duration:(NSTimeInterval)duration;

/// @name Accessing Action State

/**
 The current position of the chase-weak-target action.

 This value will be used by `update` to calculate the next position (chasing after the
 destination); a node passed to the update method will have its position set accordingly.
*/
@property (nonatomic, assign) CGPoint position;

/**
 The current value returned by the destination-providing target and selector passed to
 the initializer.
*/
@property (nonatomic, readonly) CGPoint destination;

@end

/**
 An action that tracks a relative change in z-position over a duration.
*/
@interface HLChangeZPositionByAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a change-z-position-by action.
*/
- (instancetype)initWithZPosition:(CGFloat)deltaZPosition duration:(NSTimeInterval)duration;

/// @name Accessing Action State

/**
 The instantaneous change in position of the change-z-position-by action (caused by the
 last update).

 If a node was passed to the update method, its `zPosition` was changed by this delta.
*/
@property (nonatomic, readonly) CGFloat instantaneousDelta;

@end

/**
 An action that changes z-position from one value to another over a duration.
*/
@interface HLChangeZPositionToAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a change-z-position-to action.

 When the action is first updated, it will set its original z-position based on the
 `zPosition` of the passed node.  For this reason, the node parameter passed to the first
 update must be non-nil.  (To set the original z-position without a node, use
 `initWithZFrom:to:duration:`.)
*/
- (instancetype)initWithZPositionTo:(CGFloat)zPositionTo duration:(NSTimeInterval)duration;

/**
 Creates a change-z-position-to action with a designated original z-position.
*/
- (instancetype)initWithZPositionFrom:(CGFloat)zPositionFrom to:(CGFloat)zPositionTo duration:(NSTimeInterval)duration;

/// @name Accessing Action State

/**
 The current z-position of the change-z-position-to action.

 If a node was passed to the update method, it was updated with this position.
*/
@property (nonatomic, readonly) CGFloat zPosition;

@end

/**
 An action that tracks a relative change in rotation over a duration.
*/
@interface HLRotateByAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a rotate-by action.

 Angle values are measured in radians.
*/
- (instancetype)initWithAngle:(CGFloat)angleDelta duration:(NSTimeInterval)duration;

/// @name Accessing Action State

/**
 The instantaneous change in rotation of the rotate-by action (caused by the last update).

 If a node was passed to the update method, its `zRotation` was changed by this delta.

 Angle values are measured in radians.
*/
@property (nonatomic, readonly) CGFloat instantaneousDelta;

@end

/**
 An action that rotates from one value to another over a duration.
*/
@interface HLRotateToAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a rotate-to action.

 Angle values are measured in radians.

 If `shortestUnitArc` is `YES`, the action will rotate in the direction of smallest rotation.
 This is accomplished numerically by normalizing the initial rotation into the range of the
 "angle to" value.

 If `shortestUnitArc` is `NO`, the action will change from its initial value to its final
 value by numerical interpolation between the values.  For example, rotating from 0 to 4PI
 will rotate two complete revolutions in a counter-clockwise direction, whereas rotating
 from 0 to -PI/2 will rotate a quarter turn clockwise.

 When the action is first updated, it will set its "angle from" (initial rotation) based on
 the position of the passed node.  For this reason, the node parameter passed to the first
 update must be non-nil.  (To set the initial rotation angle without a node, use
 `initWithAngleFrom:to:duration:shortestUnitArc:`.)
*/
- (instancetype)initWithAngleTo:(CGFloat)angleTo duration:(NSTimeInterval)duration shortestUnitArc:(BOOL)shortestUnitArc;

/**
 Creates a rotate-to action with optional automatic direction and a designated "angle from"
 (initial rotation).

 Angle values are measured in radians.

 If `shortestUnitArc` is `YES`, the action will rotate in the direction of smallest rotation.
 This is accomplished numerically by normalizing the initial rotation into the range of the
 "angle to" value.

 If `shortestUnitArc` is `NO`, the action will change from its initial value to its final
 value by numerical interpolation between the values.  For example, rotating from 0 to 4PI
 will rotate two complete revolutions in a counter-clockwise direction, whereas rotating
 from 0 to -PI/2 will rotate a quarter turn clockwise.
*/
- (instancetype)initWithAngleFrom:(CGFloat)angleFrom to:(CGFloat)angleTo duration:(NSTimeInterval)duration shortestUnitArc:(BOOL)shortestUnitArc;

/// @name Accessing Action State

/**
 The current rotation of the rotate-to action, in radians.

 If a node was passed to the update method, its `zRotation` was set to this value.
*/
@property (nonatomic, readonly) CGFloat angle;

/**
 The value of `angleTo` passed to the initializer.
*/
@property (nonatomic, readonly) CGFloat angleTo;

@end

/**
 An action that tracks a relative change in scale over a duration.
*/
@interface HLScaleByAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a scale-by action.
*/
- (instancetype)initWithDelta:(CGFloat)scaleDelta duration:(NSTimeInterval)duration;

/// @name Accessing Action State

/**
 The instantaneous change in scale of the scale-by action (caused by the last update).

 If a node was passed to the update method, this value was added to its x- and y-scale.
*/
@property (nonatomic, readonly) CGFloat instantaneousDelta;

@end

/**
 An action that tracks a relative change in scale over a duration.
*/
@interface HLScaleXYByAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a scale-by action.
*/
- (instancetype)initWithX:(CGFloat)scaleDeltaX y:(CGFloat)scaleDeltaY duration:(NSTimeInterval)duration;

/// @name Accessing Action State

/**
 The instantaneous change in x-scale of the scale-by action (caused by the last update).

 If a node was passed to the update method, this value was added to its x-scale.
*/
@property (nonatomic, readonly) CGFloat instantaneousDeltaX;

/**
 The instantaneous change in y-scale of the scale-by action (caused by the last update).

 If a node was passed to the update method, this value was added to its y-scale.
*/
@property (nonatomic, readonly) CGFloat instantaneousDeltaY;

/**
 The instantaneous changes in x- and y-scale of the scale-by action (caused by the last update).

 When both x and y values are needed, it is slightly more computationally efficient (though perhaps
 not measurably so) to access them through this method rather than individually through properties.
*/
- (void)getInstantaneousDeltaX:(CGFloat *)instantaneousDeltaX instantaneousDeltaY:(CGFloat *)instantaneousDeltaY;

@end

/**
 An action that changes x and y scales to new values over a duration.
*/
@interface HLScaleToAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a scale-to action.

 When the action is first updated, it will set its original x and y scale values based on
 the passed node.  For this reason, the node parameter passed to the first update must be
 non-nil.  (To set the original scale values without a node, use
 `initWithXFrom:y:xTo:y:duration:`.)
*/
- (instancetype)initWithXTo:(CGFloat)scaleXTo y:(CGFloat)scaleYTo duration:(NSTimeInterval)duration;

/**
 Creates a scale-to action with designated original scale values.
*/
- (instancetype)initWithXFrom:(CGFloat)scaleXFrom y:(CGFloat)scaleYFrom xTo:(CGFloat)scaleXTo y:(CGFloat)scaleYTo duration:(NSTimeInterval)duration;

/// @name Accessing Action State

/**
 The current x scale of the scale-to action.

 If a node was passed to the update method, it was scaled to this x scale.
*/
@property (nonatomic, readonly) CGFloat scaleX;

/**
 The current y scale of the scale-to action.

 If a node was passed to the update method, it was scaled to this y scale.
*/
@property (nonatomic, readonly) CGFloat scaleY;

/**
 The current x and y scales of the scale-to action.

 When both x and y values are needed, it is slightly more computationally efficient (though perhaps
 not measurably so) to access them through this method rather than individually through properties.
*/
- (void)getScaleX:(CGFloat *)scaleX scaleY:(CGFloat *)scaleY;

@end

/**
 An action that changes alpha by a relative value over a duration.
*/
@interface HLFadeAlphaByAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a alpha-by action.
*/
- (instancetype)initWithAlpha:(CGFloat)alphaDelta duration:(NSTimeInterval)duration;

/// @name Accessing Action State

/**
 The instantaneous change in alpha of the alpha-by action (caused by the last update).

 If a node was passed to the update method, this value was added to its alpha.
*/
@property (nonatomic, readonly) CGFloat instantaneousDelta;

@end

/**
 An action that fades alpha from one value to another.
*/
@interface HLFadeAlphaToAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates an alpha-to action.

 When the action is first updated, it will set its "alpha from" (initial alpha) based on
 the current alpha of the passed node.  For this reason, the node parameter passed to the
 first update must be non-nil.  (To set the initial alpha without a node, use
 `initWithAlphaFrom:to:duration:`.)
*/
- (instancetype)initWithAlphaTo:(CGFloat)alphaTo duration:(NSTimeInterval)duration;

/**
 Creates an alpha-to action with a designated "alpha from" (initial alpha).
*/
- (instancetype)initWithAlphaFrom:(CGFloat)alphaFrom to:(CGFloat)alphaTo duration:(NSTimeInterval)duration;

/// @name Accessing Action State

/**
 The current alpha of the alpha-to state.

 If a node was passed to the update method, it was updated with this position.
*/
@property (nonatomic, readonly) CGFloat alpha;

@end

/**
 An action that blends color and changes color blend factor (for a spite node) from one
 set of values to another.
*/
@interface HLColorizeAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a colorize action.

 When the action is first updated, it will set its initial color and blend factor based on
 the passed sprite node.  For this reason, the node parameter passed to the first update
 must be a non-nil sprite node.  (To set the initial values without a sprite node, use
 `initWithColorFrom:to:colorBlendFactorFrom:to:duration:`.)
*/
- (instancetype)initWithColor:(SKColor *)colorTo
             colorBlendFactor:(CGFloat)colorBlendFactorTo
                     duration:(NSTimeInterval)duration;

/**
 Creates a colorize action with designated initial color and blend factor.
*/
- (instancetype)initWithColorFrom:(SKColor *)colorFrom
                               to:(SKColor *)colorTo
             colorBlendFactorFrom:(CGFloat)colorBlendFactorFrom
                               to:(CGFloat)colorBlendFactorTo
                         duration:(NSTimeInterval)duration;

/**
 Creates a colorize action that only animates blend factor (not color).

 When the action is first updated, it will set its initial blend factor based on the
 passed sprite node.  For this reason, the node parameter passed to the first update must
 be a non-nil sprite node.  (To set the initial value without a sprite node, use
 `initWithColorBlendFactorFrom:to:duration:`.)
*/
- (instancetype)initWithColorBlendFactor:(CGFloat)colorBlendFactorTo
                                duration:(NSTimeInterval)duration;

/**
 Creates a colorize action that only animates blend factor (not color) and has an initial
 designated blend factor.
*/
- (instancetype)initWithColorBlendFactorFrom:(CGFloat)colorBlendFactorFrom
                                          to:(CGFloat)colorBlendFactorTo
                                    duration:(NSTimeInterval)duration;

/// @name Accessing Action State

/**
 The current color of the colorize action.

 If a sprite node was passed to the update method, it was updated with this color.
*/
@property (nonatomic, readonly) SKColor *color;

/**
 The current color blend factor of the colorize action.

 If a sprite node was passed to the update method, it was updated with this color blend
 factor.
*/
@property (nonatomic, readonly) CGFloat colorBlendFactor;

/**
 The current color and color blend factor of the colorize action.

 When both color and color blend factor are needed, it is slightly more computationally
 efficient (though perhaps not measurably so) to access them through this method rather
 than individually through properties.
*/
- (void)getColor:(SKColor * __autoreleasing *)color colorBlendFactor:(CGFloat *)colorBlendFactor;

@end

/**
 An action that progresses through an array of textures, considered as frames of an
 animation.

 If this action is being repeated, consider using `HLLoopTexturesAction` as an
 alternative; see the third and fourth encoding examples, below, for motivation.

 ### Notes

 * In the pause between frame changes, calls to `update:node:` will repeatedly set the
   current texture.  This matches the behavior of `SKAction animateWithTextures:*`.

 ### Encoding Examples

 1. Encode the animate-textures action along with the node.  (No special encoding or
    decoding code required.)

 2. Recreate the node on decoding; encode the animate-textures action separately.

     - (void)encodeWithCoder:(NSCoder *)aCoder
     {
       [super encodeWithCoder:aCoder];
       HLAction *deathAction = [_orcNode hlActionForKey:@"orc-death"];
       if (deathAction) {
         [aCoder encodeObject:deathAction forKey:@"orcNodeDeathAction"];
       }
     }

     - (instancetype)initWithCoder:(NSCoder *)aDecoder
     {
       self = [super initWithCoder:aDecoder];
       if (self) {
         // ... (after recreating _orcNode) ...
         HLAction *deathAction = [aDecoder decodeObjectForKey:"orcNodeDeathAction"];
         if (deathAction) {
           [_orcNode hlRunAction:deathAction withKey:@"orc-death"];
         }
       }
       return self;
     }

 3. Recreate both the node and the action on decoding (perhaps to save some encoding
    space).  In this case, the essential bit of the animation state to preserve and
    restore is the current frame of the animation.

     - (void)encodeWithCoder:(NSCoder *)aCoder
     {
       [super encodeWithCoder:aCoder];
       HLAction *deathAction = [_orcNode hlActionForKey:@"orc-death"];
       if (deathAction) {
         [aCoder encodeInteger:(NSInteger)deathAction.textureIndex forKey:@"orcNodeDeathActionTextureIndex"];
       }
     }

     - (instancetype)initWithCoder:(NSCoder *)aDecoder
     {
       self = [super initWithCoder:aDecoder];
       if (self) {
         // ... (after recreating _orcNode) ...
         if ([aDecoder containsValueForKey:@"orcNodeDeathActionTextureIndex"]) {
           NSUInteger textureIndex = (NSUInteger)[aDecoder decodeIntegerForKey:@"orcNodeDeathActionTextureIndex"];
           _orcNode.texture = _orcDeathFrames[textureIndex];
           NSArray *remainingFrames = [_orcDeathFrames subarrayWithRange:NSMakeRange(texureIndex, [_orcDeathFrames count] - textureIndex)];
           [_orcNode hlRunAction:[HLAction animateWithTextures:remainingFrames
                                                  timePerFrame:HLOrcDeathTimePerFrame]
                         withKey:@"orc-death"];
         }
       }
       return self;
     }

 4. Recreate both the node and the action on decoding for an animate-textures action which
    is repeated.  In this case, the first animate-textures action in the repeat must be
    created as in (3), but then the remaining ones be recreated starting at frame 0, which
    means creating a sequence containing the first action and the repeated remaining actions,
    which is ponderous.  If possible, use `HLLoopTexturesAction` instead, which handles
    this more gracefully (using a designated starting frame).
*/
@interface HLAnimateTexturesAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates an animate-textures action.

 If `restore` is `YES`, then a node must be passed non-nil to the first update of this
 action (so that this action can record the original texture).  To specify the restore
 texture without a node, use `initWithTextures:timePerFrame:resize:restoreTexture:`.)

 @param textures The frames of the animation.

 @param timePerFrame The time per frame, in seconds.

 @param resize If `YES`, then a node passed to `update:node:` will have its size changed
               to the size of the current texture.

 @param restore Whether or not to restore an original texture to the node on the final
                update (when the animation is complete).

 @return A configured animate-textures action.
*/
- (instancetype)initWithTextures:(NSArray *)textures timePerFrame:(CGFloat)timePerFrame resize:(BOOL)resize restore:(BOOL)restore;

/**
 Creates an animate-textures action with a specified restore texture.

 The parameters are the same as `initWithTextures:timePerFrame:resize:restore:` except
 that the restore texture is provided explicitly.  This means that a node does not need to
 be passed to the first update call.
*/
- (instancetype)initWithTextures:(NSArray *)textures timePerFrame:(CGFloat)timePerFrame resize:(BOOL)resize restoreTexture:(SKTexture *)restoreTexture;

/// @name Accessing Action State

/**
 The current texture.

 If a sprite node was passed to the update method, it was updated with this texture.
*/
@property (nonatomic, readonly) SKTexture *texture;

/**
 The index of the current texture (in the array of textures).
*/
@property (nonatomic, readonly) NSUInteger textureIndex;

/**
 The array of textures passed to the initializer.

 This property is readonly; textures should not be modified after initialization.
*/
@property (nonatomic, readonly) NSArray *textures;

/**
 The value of `restore` passed to the initializer.
*/
@property (nonatomic, readonly) BOOL restore;

/**
 The texture that will be restored, if any.
*/
@property (nonatomic, readonly) SKTexture *restoreTexture;

@end

/**
 An action that repeatedly cycles through an array of textures, considered as frames of an
 animation.

 One key feature: A starting frame index may be specified for the animation loop.  This is
 useful in two situations:

  * When starting a loop-textures animation at a random frame.

  * When recreating a loop-texures animation (perhaps during encoding) that was halted at
    a specific frame.

 Often the only thing interesting about a loop-texture animation is its current frame.
 This encoding example shows how a loop-texture animation can be completely recreated on
 decode from only an index:

     - (instancetype)init
     {
       // ... (after creating _orcNode) ...
       NSUInteger startingFrameIndex = (NSUInteger)arc4random_uniform((u_int32_t)[_elfWalkFrames count]);
       [_elfNode hlRunAction:[HLAction loopTextures:_elfWalkFrames
                                       timePerFrame:HLElfWalkTimePerFrame
                                             resize:YES
                                         startingAt:startingFrameIndex]
                     withKey:@"elf-walk"];
     }

     - (void)encodeWithCoder:(NSCoder *)aCoder
     {
       [super encodeWithCoder:aCoder];
       HLLoopTexturesAction *walkAction = [_orcNode hlActionForKey:@"elf-walk"];
       if (walkAction) {
         [aCoder encodeInteger:(NSInteger)walkAction.textureIndex forKey:@"elfWalkFrameIndex"];
       }
     }

     - (instancetype)initWithCoder:(NSCoder *)aDecoder
     {
       self = [super initWithCoder:aDecoder];
       if (self) {
         // ... (after recreating _orcNode) ...
         if ([aDecoder containsValueForKey:@"elfWalkFrameIndex"]) {
           NSUInteger textureIndex = (NSUInteger)[aDecoder decodeIntegerForKey:@"elfWalkFrameIndex"];
           _elfNode.texture = _elfWalkFrames[textureIndex];
           [_elfNode hlRunAction:[HLAction loopTextures:_elfWalkFrames
                                           timePerFrame:HLElfWalkTimePerFrame
                                                 resize:YES
                                             startingAt:textureIndex]
                         withKey:@"elf-walk"];
         }
       }
       return self;
     }

 ### Notes

 * In the pause between frame changes, calls to `update:node:` will repeatedly set the
   current texture.  This matches the behavior of `SKAction animateWithTextures:*`.
*/
@interface HLLoopTexturesAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a loop-textures action.

 @param textures The frames of the loop.

 @param timePerFrame The time per frame, in seconds.

 @param resize If `YES`, then a node passed to `update:node:` will have its size changed
               to the size of the current texture.

 @param startingTextureIndex The starting frame for the loop.

 @return A configured loop-textures action.
*/
- (instancetype)initWithTextures:(NSArray *)textures timePerFrame:(CGFloat)timePerFrame resize:(BOOL)resize startingAt:(NSUInteger)startingTextureIndex;

/// @name Accessing Action State

/**
 The current texture.

 If a sprite node was passed to the update method, it was updated with this texture.
*/
@property (nonatomic, readonly) SKTexture *texture;

/**
 The index of the current texture (in the array of textures).
*/
@property (nonatomic, readonly) NSUInteger textureIndex;

/**
 The array of textures passed to the initializer.

 This property is readonly; textures should not be modified after initialization.
*/
@property (nonatomic, readonly) NSArray *textures;

/**
 The value of `timePerFrame` passed to the initializer.
*/
@property (nonatomic, readonly) CGFloat timePerFrame;

@end

/**
 A non-durational action that removes a node from its parent.
*/
@interface HLRemoveFromParentAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a remove-from-parent action.
*/
- (instancetype)init;

@end

/**
 A non-durational action that performs a selector on a target.

 This variant retains the target weakly and passes no arguments to the selector.

 ## Avoid Retain Cycles

 The perform-selector provided by SpriteKit retains its target strongly, which can lead to
 a retain cycle when the target is the node running the action.  For example, a sequence
 like this is problematic:

     SKAction *delayedPing = [SKAction sequence:@[ [SKAction waitForDuration:1.0],
                                                   [SKAction performSelector:@selector(ping) onTarget:self] ]];
     [self runAction:delayedPing];

 If, during the one-second wait, this node is removed from parent, then its actions will
 be paused (not released!), and the node and action will retain each other strongly.

 To address this, `HLPerformSelectorWeakAction` (and its variants) retain their target
 weakly.

 This module contains "strong" variants of the perform-selector which correspond more
 closely to the behavior of `performSelector:onTarget:`.  They are not recommended.
*/
@interface HLPerformSelectorWeakAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a perform-selector action.

 @param weakTarget The target, retained weakly in order to avoid retain cycles.  (One
                   possible cycle, when the target is the parent of the child node running
                   the action: The target retains the child node; the child node retains
                   the action runner; the action runner retains the action; the action
                   retains the target.)

 @param selector The selector (taking no arguments) to be performed by the action.
*/
- (instancetype)initWithWeakTarget:(id)weakTarget selector:(SEL)selector;

@end

/**
 A non-durational action that performs a selector on a target.

 This variant retains the target weakly and passes a single argument to the selector.
*/
@interface HLPerformSelectorWeakSingleAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a perform-selector action.

 @param weakTarget The target, retained weakly in order to avoid retain cycles.  (One
                   possible cycle, when the target is the parent of the child node running
                   the action: The target retains the child node; the child node retains
                   the action runner; the action runner retains the action; the action
                   retains the target.)

 @param selector The selector (taking a single argument) to be performed by the action.

 @param argument The argument to pass to the selector when it is performed.
*/
- (instancetype)initWithWeakTarget:(id)weakTarget selector:(SEL)selector argument:(id)argument;

@end

/**
 A non-durational action that performs a selector on a target.

 This variant retains the target weakly and passes two arguments to the selector.
*/
@interface HLPerformSelectorWeakDoubleAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a perform-selector action.

 @param weakTarget The target, retained weakly in order to avoid retain cycles.  (One
                   possible cycle, when the target is the parent of the child node running
                   the action: The target retains the child node; the child node retains
                   the action runner; the action runner retains the action; the action
                   retains the target.)

 @param selector The selector (taking two arguments) to be performed by the action.

 @param argument1 The first argument to pass to the selector when it is performed.

 @param argument2 The second argument to pass to the selector when it is performed.
*/
- (instancetype)initWithWeakTarget:(id)weakTarget selector:(SEL)selector argument1:(id)argument1 argument2:(id)argument2;

@end

/**
 A non-durational action that performs a selector on a target.

 This variant retains the target strongly and passes no arguments to the selector.
*/
@interface HLPerformSelectorStrongAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a perform-selector action.

 @param strongTarget The target, retained strongly.  Be careful of retain cycles.  (One
                     possible cycle, when the target is the parent of the child node
                     running the action: The target retains the child node; the child node
                     retains the action runner; the action runner retains the action; the
                     action retains the target.)

 @param selector The selector (taking no arguments) to be performed by the action.
*/
- (instancetype)initWithStrongTarget:(id)strongTarget selector:(SEL)selector;

@end

/**
 A non-durational action that performs a selector on a target.

 This variant retains the target strongly and passes a single argument to the selector.
*/
@interface HLPerformSelectorStrongSingleAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a perform-selector action.

 @param strongTarget The target, retained strongly.  Be careful of retain cycles.  (One
                     possible cycle, when the target is the parent of the child node
                     running the action: The target retains the child node; the child node
                     retains the action runner; the action runner retains the action; the
                     action retains the target.)

 @param selector The selector (taking a single argument) to be performed by the action.

 @param argument The argument to pass to the selector when it is performed.
*/
- (instancetype)initWithStrongTarget:(id)strongTarget selector:(SEL)selector argument:(id)argument;

@end

/**
 A non-durational action that performs a selector on a target.

 This variant retains the target strongly and passes two arguments to the selector.
*/
@interface HLPerformSelectorStrongDoubleAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a perform-selector action.

 @param strongTarget The target, retained strongly.  Be careful of retain cycles.  (One
                     possible cycle, when the target is the parent of the child node
                     running the action: The target retains the child node; the child node
                     retains the action runner; the action runner retains the action; the
                     action retains the target.)

 @param selector The selector (taking two arguments) to be performed by the action.

 @param argument1 The first argument to pass to the selector when it is performed.

 @param argument2 The second argument to pass to the selector when it is performed.
*/
- (instancetype)initWithStrongTarget:(id)strongTarget selector:(SEL)selector argument1:(id)argument1 argument2:(id)argument2;

@end

/**
 An action that performs a selector on a target repeatedly over a duration.

 ## Example

 A tweening example, moving a node using a "ease out back" easing curve with user data.

     #import "HLSpriteKit/HLAction.h"
     #import "HLSpriteKit/SKNode+HLAction.h"

     ...
     HLCustomActionTwoPoint *moveUserData = [[HLCustomActionTwoPoint alloc] init];
     moveUserData.start = CGPointMake(-100.0f, -100.0f);
     moveUserData.finish = CGPointMake(100.0f, 100.0f);

     SKSpriteNode *redNode = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(100.0f, 100.0f)];
     [redNode hlRunAction:[HLAction customActionWithDuration:3.0
                                                    selector:@selector(HL_moveNode:elapsedTime:duration:userData:)
                                                  weakTarget:self
                                                    userData:moveUserData]];
     ...
     [redNode hlActionRunnerUpdate:incrementalTime];
     ...

     - (void)HL_moveNode:(SKNode *)node
             elapsedTime:(CGFloat)elapsedTime
                duration:(NSTimeInterval)duration
                userData:(HLCustomActionTwoPoints *)userData {
       CGFloat normalTime = (CGFloat)(elapsedTime / duration);
       CGFloat normalValue = BackEaseOut(normalTime);
       CGPoint position;
       position.x = userData.start.x * (1.0f - normalValue) + userData.finish.x * normalValue;
       position.y = userData.start.y * (1.0f - normalValue) + userData.finish.y * normalValue;
       node.position = position;
     }
*/
@interface HLCustomAction : HLAction <NSCoding, NSCopying>

/// @name Creating the Action

/**
 Creates a custom action.

 @param weakTarget The target, retained weakly in order to avoid retain cycles.  (One
                   possible cycle, when the target is the parent of the child node running
                   the action: The target retains the child node; the child node retains
                   the action runner; the action runner retains the action; the action
                   retains the target.)

 @param selector The selector that will be performed repeatedly over the duration.  It is
                 passed four parameters: the updated node (`SKNode *`), the elapsed time
                 (`CGFloat`), the action duration (`NSTimeInterval`), and the user data
                 (`id`).

 @param duration The duration of the action, in seconds.

 @param userData An object which will be retained (strongly) on the custom action and
                 passed as a parameter to the selector.
*/
- (instancetype)initWithWeakTarget:(id)weakTarget
                          selector:(SEL)selector
                          duration:(NSTimeInterval)duration
                          userData:(id)userData;

/// @name Accessing Action State

/**
 The user data object passed to the initializer.
*/
@property (nonatomic, strong) id userData;

@end

/**
 Convenience initializers for creating `HLAction` actions.
*/
@interface HLAction (HLActions)

/**
 Creates an action that updates a collection of actions in parallel.

 @param actions An array of `HLAction` actions.

 @return An initialized group action.
*/
+ (HLGroupAction *)group:(NSArray *)actions;

/**
 Creates an action that updates a collection of actions in sequence.

 @param actions An array of `HLAction` actions.

 @return An initialized sequence action.
*/
+ (HLSequenceAction *)sequence:(NSArray *)actions;

/**
 Creates an action that repeats another action forever.

 The action to be repeated is retained strongly, and copied on each iteration immediately
 before it is run.
*/
+ (HLRepeatAction *)repeatAction:(HLAction *)action count:(NSUInteger)count;

/**
 Creates an action that repeats another action the passed number of times.

 The action to be repeated is retained strongly, and copied on each iteration immediately
 before it is run.

 If count is passed 0, the action will be repeated forever.
*/
+ (HLRepeatAction *)repeatActionForever:(HLAction *)action;

/**
 Creates an action that idles for a duration.
*/
+ (HLWaitAction *)waitForDuration:(NSTimeInterval)duration;

/**
 Creates an action that tracks a relative change in position over a duration.
*/
+ (HLMoveByAction *)moveByX:(CGFloat)deltaX y:(CGFloat)deltaX duration:(NSTimeInterval)duration;

/**
 Creates an action that tracks a relative change in position over a duration.
*/
+ (HLMoveByAction *)moveBy:(CGPoint)delta duration:(NSTimeInterval)duration;

/**
 Creates an action that moves from one point to another over a duration.

 When the action is first updated, it will set its origin based on the position of the
 passed node.  For this reason, the node parameter passed to the first update must be
 non-nil.  (To set the origin without a node, use `moveFrom:to:destination:duration:`.)
*/
+ (HLMoveToAction *)moveTo:(CGPoint)destination duration:(NSTimeInterval)duration;

/**
 Creates an action that moves from one point to another over a duration, with a designated
 origin.
*/
+ (HLMoveToAction *)moveFrom:(CGPoint)origin to:(CGPoint)destination duration:(NSTimeInterval)duration;

//+ (HLMoveToXAction *)moveToX:(CGFloat)xTo duration:(NSTimeInterval)duration;
//+ (HLMoveToXAction *)moveFromX:(CGFloat)xFrom to:(CGFloat)xTo duration:(NSTimeInterval)duration;
//+ (HLMoveToYAction *)moveToY:(CGFloat)yTo duration:(NSTimeInterval)duration;
//+ (HLMoveToYAction *)moveFromY:(CGFloat)yFrom to:(CGFloat)yTo duration:(NSTimeInterval)duration;

/**
 Creates an action that moves from a fixed point to a changeable point over a duration.
*/
+ (HLChaseAction *)chase:(CGPoint)destination duration:(NSTimeInterval)duration;

/**
 Creates an action that moves from a fixed point to a changeable point over a duration,
 with a designated origin.
*/
+ (HLChaseAction *)chaseFrom:(CGPoint)origin to:(CGPoint)destination duration:(NSTimeInterval)duration;

/**
 Creates an action that moves from a fixed point to a changeable point (provided by a
 callback) over a duration.
*/
+ (HLChaseWeakTargetAction *)chaseWeakTarget:(id)destinationWeakTarget selector:(SEL)destinationSelector duration:(NSTimeInterval)duration;

/**
 Creates an action that moves from a fixed point to a changeable point (provided by a
 callback) over a duration, with a designated origin.
*/
+ (HLChaseWeakTargetAction *)chaseFrom:(CGPoint)origin toWeakTarget:(id)destinationWeakTarget selector:(SEL)destinationSelector duration:(NSTimeInterval)duration;

/**
 Creates an action that tracks a relative change in z-position over a duration.
*/
+ (HLChangeZPositionByAction *)changeZPositionBy:(CGFloat)zPositionDelta duration:(NSTimeInterval)duration;

/**
 Creates an action that changes z-position from one value to another over a duration.

 When the action is first updated, it will set its original z-position based on the
 `zPosition` of the passed node.  For this reason, the node parameter passed to the first
 update must be non-nil.  (To set the original z-position without a node, use
 `changeZPositionFrom:to:duration:`.)
*/
+ (HLChangeZPositionToAction *)changeZPositionTo:(CGFloat)zPositionTo duration:(NSTimeInterval)duration;

/**
 Creates an action that changes z-position from one value to another over a duration, with
 a designated original z-position.
*/
+ (HLChangeZPositionToAction *)changeZPositionFrom:(CGFloat)zPositionFrom to:(CGFloat)zPositionTo duration:(NSTimeInterval)duration;

/**
 Creates an action that tracks a relative change in rotation over a duration.

 Angle values are measured in radians.
*/
+ (HLRotateByAction *)rotateByAngle:(CGFloat)angleDelta duration:(NSTimeInterval)duration;

/**
 Creates an action that rotates from one value to another over a duration.

 Angle values are measured in radians.

 The action will change from its initial value to its final value by numerical
 interpolation between the values.  For example, rotating from 0 to 4PI will rotate two
 complete revolutions in a counter-clockwise direction, whereas rotating from 0 to -PI/2
 will rotate a quarter turn clockwise.

 When the action is first updated, it will set its "angle from" (initial rotation) based
 on the position of the passed node.  For this reason, the node parameter passed to the
 first update must be non-nil.  (To set the initial rotation angle without a node, use
 `rotateFromAngle:to:duration:`.)
*/
+ (HLRotateToAction *)rotateToAngle:(CGFloat)angleTo duration:(NSTimeInterval)duration;

/**
 Creates an action that rotates from one value to another over a duration, with a
 designated "angle from" (initial rotation).

 Angle values are measured in radians.

 The action will change from its initial value to its final value by numerical
 interpolation between the values.  For example, rotating from 0 to 4PI will rotate two
 complete revolutions in a counter-clockwise direction, whereas rotating from 0 to -PI/2
 will rotate a quarter turn clockwise.
*/
+ (HLRotateToAction *)rotateFromAngle:(CGFloat)angleFrom to:(CGFloat)angleTo duration:(NSTimeInterval)duration;

/**
 Creates an action that rotates from one value to another over a duration, with optional
 automatic direction.

 Angle values are measured in radians.

 If `shortestUnitArc` is `YES`, the action will rotate in the direction of smallest
 rotation.  This is accomplished numerically by normalizing the initial rotation into the
 range of the "angle to" value.

 If `shortestUnitArc` is `NO`, the action will change from its initial value to its final
 value by numerical interpolation between the values.  For example, rotating from 0 to 4PI
 will rotate two complete revolutions in a counter-clockwise direction, whereas rotating
 from 0 to -PI/2 will rotate a quarter turn clockwise.

 When the action is first updated, it will set its "angle from" (initial rotation) based
 on the position of the passed node.  For this reason, the node parameter passed to the
 first update must be non-nil.  (To set the initial rotation angle without a node, use
 `rotateFromAngle:to:duration:shortestUnitArc:`.)
*/
+ (HLRotateToAction *)rotateToAngle:(CGFloat)angleTo duration:(NSTimeInterval)duration shortestUnitArc:(BOOL)shortestUnitArc;

/**
 Creates an action that rotates from one value to another over a duration, with optional
 automatic direction and a designated "angle from" (initial rotation).

 Angle values are measured in radians.

 If `shortestUnitArc` is `YES`, the action will rotate in the direction of smallest
 rotation.  This is accomplished numerically by normalizing the initial rotation into the
 range of the "angle to" value.

 If `shortestUnitArc` is `NO`, the action will change from its initial value to its final
 value by numerical interpolation between the values.  For example, rotating from 0 to 4PI
 will rotate two complete revolutions in a counter-clockwise direction, whereas rotating
 from 0 to -PI/2 will rotate a quarter turn clockwise.
*/
+ (HLRotateToAction *)rotateFromAngle:(CGFloat)angleFrom to:(CGFloat)angleTo duration:(NSTimeInterval)duration shortestUnitArc:(BOOL)shortestUnitArc;

/**
 Creates an action that tracks a relative change in scale over a duration.
*/
+ (HLScaleByAction *)scaleBy:(CGFloat)scaleDelta duration:(NSTimeInterval)duration;

/**
 Creates an action that tracks a relative change in scale over a duration, with
 individually-specified scale changes for x and y.
*/
+ (HLScaleXYByAction *)scaleXBy:(CGFloat)scaleDeltaX y:(CGFloat)scaleDeltaY duration:(NSTimeInterval)duration;

/**
 Creates an action that changes x and y scales to the same new scale value over a
 duration.

 When the action is first updated, it will set its initial x and y scale values based on
 the passed node.  For this reason, the node parameter passed to the first update must be
 non-nil.  (To set the initial scale values without a node, use
 `scaleXFrom:y:to:duration:`.)
*/
+ (HLScaleToAction *)scaleTo:(CGFloat)scaleTo duration:(NSTimeInterval)duration;

/**
 Creates an action that changes x and y scales the same new scale value over a duration,
 with designated initial scale values.
*/
+ (HLScaleToAction *)scaleXFrom:(CGFloat)scaleXFrom y:(CGFloat)scaleYFrom to:(CGFloat)scaleTo duration:(NSTimeInterval)duration;

/**
 Creates an that changes x and y scales to two new scale values over a duration.

 When the action is first updated, it will set its initial x and y scale values based on
 the passed node.  For this reason, the node parameter passed to the first update must be
 non-nil.  (To set the initial scale values without a node, use
 `scaleXFrom:y:xTo:y:duration:`.)
*/
+ (HLScaleToAction *)scaleXTo:(CGFloat)scaleXTo y:(CGFloat)scaleYTo duration:(NSTimeInterval)duration;

/**
 Creates an that changes x and y scales to two new scale values over a duration, with
 designated initial scale vlaues.
*/
+ (HLScaleToAction *)scaleXFrom:(CGFloat)scaleXFrom y:(CGFloat)scaleYFrom xTo:(CGFloat)scaleXTo y:(CGFloat)scaleYTo duration:(NSTimeInterval)duration;

//+ (HLScaleXToAction *)scaleXTo:(CGFloat)scaleXTo duration:(NSTimeInterval)duration;
//+ (HLScaleXToAction *)scaleXFrom:(CGFloat)scaleXFrom to:(CGFloat)scaleXTo duration:(NSTimeInterval)duration;
//+ (HLScaleYToAction *)scaleYTo:(CGFloat)scaleYTo duration:(NSTimeInterval)duration;
//+ (HLScaleYToAction *)scaleYFrom:(CGFloat)scaleYFrom to:(CGFloat)scaleYTo duration:(NSTimeInterval)duration;

/**
 Creates an action that changes alpha by a relative value over a duration.
*/
+ (HLFadeAlphaByAction *)fadeAlphaBy:(CGFloat)alphaDelta duration:(NSTimeInterval)duration;

/**
 Creates an action that fades alpha to `1.0` over a duration.

 When the action is first updated, it will set its "alpha from" (initial alpha) based on
 the current alpha of the passed node.  For this reason, the node parameter passed to the
 first update must be non-nil.  (To set the initial alpha without a node, use
 `fadeInFrom:duration:`.)
*/
+ (HLFadeAlphaToAction *)fadeInWithDuration:(NSTimeInterval)duration;

/**
 Creates an action that fades alpha to `1.0` over a duration, with a designated initial
 alpha value.
*/
+ (HLFadeAlphaToAction *)fadeInFrom:(CGFloat)alphaFrom duration:(NSTimeInterval)duration;

/**
 Creates an action that fades alpha to `0.0` over a duration.

 When the action is first updated, it will set its "alpha from" (initial alpha) based on
 the current alpha of the passed node.  For this reason, the node parameter passed to the
 first update must be non-nil.  (To set the initial alpha without a node, use
 `fadeOutFrom:duration:`.)
*/
+ (HLFadeAlphaToAction *)fadeOutWithDuration:(NSTimeInterval)duration;

/**
 Creates an action that fades alpha to `0.0` over a duration, with a designated initial
 alpha value.
*/
+ (HLFadeAlphaToAction *)fadeOutFrom:(CGFloat)alphaFrom duration:(NSTimeInterval)duration;

/**
 Creates an action that fades alpha from one value to another.

 When the action is first updated, it will set its "alpha from" (initial alpha) based on
 the current alpha of the passed node.  For this reason, the node parameter passed to the
 first update must be non-nil.  (To set the initial alpha without a node, use
 `fadeAlphaFrom:to:duration:`.)
*/
+ (HLFadeAlphaToAction *)fadeAlphaTo:(CGFloat)alphaTo duration:(NSTimeInterval)duration;

/**
 Creates an action that fades alpha from one value to another, with a designated initial
 alpha value.
*/
+ (HLFadeAlphaToAction *)fadeAlphaFrom:(CGFloat)alphaFrom to:(CGFloat)alphaTo duration:(NSTimeInterval)duration;

/**
 Creates an action that blends color and changes color blend factor (for a spite node)
 from one set of values to another.

 When the action is first updated, it will set its initial color and blend factor based on
 the passed sprite node.  For this reason, the node parameter passed to the first update
 must be a non-nil sprite node.  (To set the initial values without a sprite node, use
 `colorizeWithColorFrom:to:colorBlendFactorFrom:to:duration:`.)
*/
+ (HLColorizeAction *)colorizeWithColor:(SKColor *)colorTo colorBlendFactor:(CGFloat)colorBlendFactorTo duration:(NSTimeInterval)duration;

/**
 Creates an action that blends color and changes color blend factor (for a spite node)
 from one set of values to another, with designated initial color and blend factor.
*/
+ (HLColorizeAction *)colorizeWithColorFrom:(SKColor *)colorFrom to:(SKColor *)colorTo colorBlendFactorFrom:(CGFloat)colorBlendFactorFrom to:(CGFloat)colorBlendFactorTo duration:(NSTimeInterval)duration;

/**
 Creates an action that changes color blend factor (for a sprite node) from one value to
 another.

 When the action is first updated, it will set its initial blend factor based on the
 passed sprite node.  For this reason, the node parameter passed to the first update must
 be a non-nil sprite node.  (To set the initial value without a sprite node, use
 `colorizeWithColorBlendFactorFrom:to:duration:`.)
*/
+ (HLColorizeAction *)colorizeWithColorBlendFactor:(CGFloat)colorBlendFactorTo duration:(NSTimeInterval)duration;

/**
 Creates an action that changes color blend factor (for a sprite node) from one value to
 another, with designated color blend factor.
*/
+ (HLColorizeAction *)colorizeWithColorBlendFactorFrom:(CGFloat)colorBlendFactorFrom to:(CGFloat)colorBlendFactorTo duration:(NSTimeInterval)duration;

/**
 Creates an action that progresses through an array of textures, considered as frames of
 an animation.

 If this action is being repeated, consider using `HLLoopTexturesAction` as an
 alternative; see `HLAnimateTexturesAction` documentation for details.
*/
+ (HLAnimateTexturesAction *)animateWithTextures:(NSArray *)textures timePerFrame:(NSTimeInterval)timePerFrame;

/**
 Creates an action that progresses through an array of textures, considered as frames of
 an animation.

 If this action is being repeated, consider using `HLLoopTexturesAction` as an
 alternative; see `HLAnimateTexturesAction` documentation for details.

 If `restore` is `YES`, then a node must be passed non-nil to the first update of this
 action (so that this action can record the original texture).  To specify the restore
 texture without a node, use `animateWithTextures:timePerFrame:resize:restoreTexture:`.)

 @param textures The frames of the animation.

 @param timePerFrame The time per frame, in seconds.

 @param resize If `YES`, then a node passed to `update:node:` will have its size changed
               to the size of the current texture.

 @param restore Whether or not to restore an original texture to the node on the final
                update (when the animation is complete).

 @return A configured animate-textures action.
*/
+ (HLAnimateTexturesAction *)animateWithTextures:(NSArray *)textures timePerFrame:(NSTimeInterval)timePerFrame resize:(BOOL)resize restore:(BOOL)restore;

/**
 Creates an action that progresses through an array of textures, considered as frames of
 an animation.

 If this action is being repeated, consider using `HLLoopTexturesAction` as an
 alternative; see `HLAnimateTexturesAction` documentation for details.

 @param textures The frames of the animation.

 @param timePerFrame The time per frame, in seconds.

 @param resize If `YES`, then a node passed to `update:node:` will have its size changed
               to the size of the current texture.

 @param restoreTexture The texture to restore to the node on the final update (when the
                       animation is complete).

 @return A configured animate-textures action.
*/
+ (HLAnimateTexturesAction *)animateWithTextures:(NSArray *)textures timePerFrame:(NSTimeInterval)timePerFrame resize:(BOOL)resize restoreTexture:(SKTexture *)restoreTexture;

/**
 Creates an action that repeatedly cycles through an array of textures, considered as
 frames of an animation.
*/
+ (HLLoopTexturesAction *)loopTextures:(NSArray *)textures timePerFrame:(NSTimeInterval)timePerFrame;

/**
 Creates an action that repeatedly cycles through an array of textures, considered as
 frames of an animation.

 @param textures The frames of the loop.

 @param timePerFrame The time per frame, in seconds.

 @param resize If `YES`, then a node passed to `update:node:` will have its size changed
               to the size of the current texture.

 @param startingTextureIndex The starting frame for the loop.

 @return A configured loop-textures action.
*/
+ (HLLoopTexturesAction *)loopTextures:(NSArray *)textures timePerFrame:(NSTimeInterval)timePerFrame resize:(BOOL)resize startingAt:(NSUInteger)startingTextureIndex;

/**
 Creates a non-durational action that removes a node from its parent.
*/
+ (HLRemoveFromParentAction *)removeFromParent;

/**
 Creates a non-durational action that performs a selector on a target.

 This variant retains the target weakly and passes no arguments to the selector.

 @param weakTarget The target, retained weakly in order to avoid retain cycles.  (One
                   possible cycle, when the target is the parent of the child node running
                   the action: The target retains the child node; the child node retains
                   the action runner; the action runner retains the action; the action
                   retains the target.)

 @param selector The selector (taking two arguments) to be performed by the action.
*/
+ (HLPerformSelectorWeakAction *)performSelector:(SEL)selector onWeakTarget:(id)weakTarget;

/**
 Creates a non-durational action that performs a selector on a target.

 This variant retains the target weakly and passes a single argument to the selector.

 @param weakTarget The target, retained weakly in order to avoid retain cycles.  (One
                   possible cycle, when the target is the parent of the child node running
                   the action: The target retains the child node; the child node retains
                   the action runner; the action runner retains the action; the action
                   retains the target.)

 @param selector The selector (taking two arguments) to be performed by the action.

 @param argument The argument to pass to the selector when it is performed.
*/
+ (HLPerformSelectorWeakSingleAction *)performSelector:(SEL)selector onWeakTarget:(id)weakTarget withArgument:(id)argument;

/**
 Creates a non-durational action that performs a selector on a target.

 This variant retains the target weakly and passes two arguments to the selector.

 @param weakTarget The target, retained weakly in order to avoid retain cycles.  (One
                   possible cycle, when the target is the parent of the child node running
                   the action: The target retains the child node; the child node retains
                   the action runner; the action runner retains the action; the action
                   retains the target.)

 @param selector The selector (taking two arguments) to be performed by the action.

 @param argument1 The first argument to pass to the selector when it is performed.

 @param argument2 The second argument to pass to the selector when it is performed.
*/
+ (HLPerformSelectorWeakDoubleAction *)performSelector:(SEL)selector onWeakTarget:(id)weakTarget withArgument1:(id)argument1 argument2:(id)argument2;

/**
 Creates a non-durational action that performs a selector on a target.

 This variant retains the target strongly and passes no arguments to the selector.

 @param strongTarget The target, retained strongly.  Be careful of retain cycles.  (One
                     possible cycle, when the target is the parent of the child node
                     running the action: The target retains the child node; the child node
                     retains the action runner; the action runner retains the action; the
                     action retains the target.)

 @param selector The selector (taking two arguments) to be performed by the action.
*/
+ (HLPerformSelectorStrongAction *)performSelector:(SEL)selector onStrongTarget:(id)strongTarget;

/**
 Creates a non-durational action that performs a selector on a target.

 This variant retains the target strongly and passes a single argument to the selector.

 @param strongTarget The target, retained strongly.  Be careful of retain cycles.  (One
                     possible cycle, when the target is the parent of the child node
                     running the action: The target retains the child node; the child node
                     retains the action runner; the action runner retains the action; the
                     action retains the target.)

 @param selector The selector (taking two arguments) to be performed by the action.

 @param argument The argument to pass to the selector when it is performed.
*/
+ (HLPerformSelectorStrongSingleAction *)performSelector:(SEL)selector onStrongTarget:(id)strongTarget withArgument:(id)argument;

/**
 Creates a non-durational action that performs a selector on a target.

 This variant retains the target strongly and passes two arguments to the selector.

 @param strongTarget The target, retained strongly.  Be careful of retain cycles.  (One
                     possible cycle, when the target is the parent of the child node
                     running the action: The target retains the child node; the child node
                     retains the action runner; the action runner retains the action; the
                     action retains the target.)

 @param selector The selector (taking two arguments) to be performed by the action.

 @param argument1 The first argument to pass to the selector when it is performed.

 @param argument2 The second argument to pass to the selector when it is performed.
*/
+ (HLPerformSelectorStrongDoubleAction *)performSelector:(SEL)selector onStrongTarget:(id)strongTarget withArgument1:(id)argument1 argument2:(id)argument2;

/**
 Creates an action that performs a selector on a target repeatedly over a duration.

 @param duration The duration of the action, in seconds.

 @param selector The selector that will be performed repeatedly over the duration.  It is
                 passed four parameters: the updated node (`SKNode *`), the elapsed time
                 (`CGFloat`), the action duration (`NSTimeInterval`), and the user data
                 (`id`).

 @param weakTarget The target, retained weakly in order to avoid retain cycles.  (One
                   possible cycle, when the target is the parent of the child node running
                   the action: The target retains the child node; the child node retains
                   the action runner; the action runner retains the action; the action
                   retains the target.)

 @param userData An object which will be retained (strongly) on the custom action and
                 passed as a parameter to the selector.
*/
+ (HLCustomAction *)customActionWithDuration:(NSTimeInterval)duration
                                    selector:(SEL)selector
                                  weakTarget:(id)weakTarget
                                    userData:(id)userData;

@end

/**
 A commonly-useful encodable user data object to use with `HLCustomAction`.

 A common use case for `HLCustomAction` is tweening between two values (whether position,
 alpha, scale, or something else), which can be tracked by this user data object.  In the
 following example, a user data object is provided to the custom action in order to track
 a start and finish value for an overshooting slide.

     - (void)slideNode:(SKNode *)node
     {
       HLCustomActionTwoValues *slideUserData = [[HLCustomActionTwoValues alloc] init];
       slideUserData.start = node.position.x;
       slideUserData.finish = self.size.width / 2.0f;

       HLCustomAction *slideAction = [HLAction customActionWithDuation:2.0
                                                              selector:@selector(slideUpdate:elapsedTime:duration:userData:)
                                                            weakTarget:self
                                                              userData:slideUserData];
       [_actionRunner runAction:slideAction.action];
     }

     - (void)slideUpdate:(SKNode *)node
             elapsedTime:(CGFloat)elapsedTime
                duration:(NSTimeInterval)duration
                userData:(HLCustomActionEndPoints *)userData
     {
       CGFloat normalTime = (CGFloat)(elapsedTime / duration);
       CGFloat normalValue = BackStandardEaseInOut(normalTime);
       node.position = CGPointMake(userData.start * (1.0f - normalValue) + userData.finish * normalValue, 0.0f);
     }
*/
@interface HLCustomActionTwoValues : NSObject <NSCoding, NSCopying>

@property (nonatomic, assign) CGFloat start;

@property (nonatomic, assign) CGFloat finish;

@end

/**
 A commonly-useful encodable user data object to use with `HLCustomAction`.

 See notes for `HLCustomActionTwoValues`.  This is the same idea, but offering a start
 and finish `CGPoint` rather than `CGFloat`.
*/
@interface HLCustomActionTwoPoints : NSObject <NSCoding, NSCopying>

@property (nonatomic, assign) CGPoint start;

@property (nonatomic, assign) CGPoint finish;

@end
