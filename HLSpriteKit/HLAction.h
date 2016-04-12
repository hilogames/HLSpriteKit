//
//  HLAction.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 2/4/16.
//  Copyright (c) 2016 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

/**
 A lightweight encodable object that, when triggered, can perform a selector on a
 strongly-retained target with a single argument.

 Intended as a replacement for `SKAction runBlock:`, which is more versatile, but which
 cannot be encoded.

 See http://stackoverflow.com/q/35249269/1332415 for context.

 Details
 -------

 When the node hierarchy is encoded, as is common during application state preservation or
 a "game save", nodes running `SKAction` actions with code blocks must be handled
 specially, since the code blocks cannot be encoded.

 For example, say an orc has been killed.  It is animated to fade out and then remove
 itself from the node hierarchy:

     SKAction *fadeAction = [SKAction fadeOutWithDuration:3.0];
     SKAction *removeAction = [SKAction removeFromParent];
     [orcNode runAction:[SKAction sequence:@[ fadeAction, removeAction ]]];

 If the orc node is encoded and then decoded, the animation will restore properly and
 complete as expected.

 But now the example is modified to use a code block that runs after the fade.  Perhaps
 the code cleans up some game state once the orc is (finally) dead.

     SKAction *fadeAction = [SKAction fadeOutWithDuration:3.0];
     SKAction *removeAction = [SKAction removeFromParent];
     SKAction *cleanupAction = [SKAction runBlock:^{
       [self orcDidFinishDying:orcNode];
     }];
     [orcNode runAction:[SKAction sequence:@[ fadeAction, removeAction, cleanupAction ]]];

 Unfortunately, the code block will not encode.  During application state preservation (or
 game save), if this sequence is running, a warning will be issued:

   > SKAction: Run block actions can not be properly encoded,
   > Objective-C blocks do not support NSCoding.

 After decoding, the orc will fade and be removed from parent, but the cleanup method
 `orcDidFinishDying:` will not be called.

 Instead, use `HLPerformSelectorStrongSingle` (or another variant).

   - The caller instantiates the perform-selector object and sets its properties: target,
     selector, and arguments.

   - The perform-selector object is triggered in a `runAction` animation by the standard
     no-argument `[SKAction performSelector:onTarget:]`.  For this triggering action, the
     target is the perform-selector object and the selector is a designated `execute`
     method.  (As shorthand, the `action` method of the perform-selector object returns a
     properly constructed `SKAction`.)

   - The perform-selector object conforms to `NSCoding`.

   - As a bonus, the triggering `SKAction` retains a strong reference to the
     perform-selector object, and so both will be encoded along with the node running the
     actions.

 Special Considerations
 ----------------------

 When a node is encoded with a running (not yet completed) `SKAction`, and then decoded,
 it will restart the `SKAction` from the beginning.  This is standard SpriteKit behavior.

 The behavior can be surprising, though, when this perform-selector action is running in a
 sequence: Upon decoding, the entire sequence (if it is not yet completed) will restart
 from the beginning, and even if this perform-selector object was performed before
 preservation, it will perform again after restoration.

 See `HLSequence` for an alternative; upon decoding, it will not re-run parts of the
 sequence that have already completed.

 Examples
 --------

 Example with manual creation of triggering `SKAction`.

     SKAction *fadeAction = [SKAction fadeOutWithDuration:3.0];
     SKAction *removeAction = [SKAction removeFromParent];
     HLPerformSelectorStrongSingle *cleanupCaller = [[HLPerformSelectorStrongSingle alloc] initWithStrongTarget:self selector:@selector(orcDidFinishDying:) argument:orcNode];
     SKAction *cleanupAction = [SKAction performSelector:@selector(execute) onTarget:cleanupCaller];
     [orcNode runAction:[SKAction sequence:@[ fadeAction, removeAction, cleanupAction ]]];

 Example using `action` method shorthand.

     SKAction *fadeAction = [SKAction fadeOutWithDuration:3.0];
     SKAction *removeAction = [SKAction removeFromParent];
     HLPerformSelectorStrongSingle *cleanupCaller = [[HLPerformSelectorStrongSingle alloc] initWithStrongTarget:self selector:@selector(orcDidFinishDying:) argument:orcNode];
     [orcNode runAction:[SKAction sequence:@[ fadeAction, removeAction, cleanupCaller.action ]]];
*/
@interface HLPerformSelectorStrongSingle : NSObject <NSCoding>

/// @name Creating a Perform-Selector Object

/**
 Initializes a perform-selector object with all properties.
*/
- (instancetype)initWithStrongTarget:(id)strongTarget selector:(SEL)selector argument:(id)argument;

/**
 The target the selector will be performed on, when triggered.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the argument.

 The target is retained strongly, despite the potential for retain cycles:

  - Typically, the target is a controller that is also the parent node of the child
    running the animation sequence.

  - The target, therefore, retains the child; the child retains its running `SKActions`;
    and the no-argument triggering `performSelector:onTarget:` retains this
    perform-selector object.

  - This perform-selector object retains the target, completing the cycle.  Such a cycle
    might be appropriate for a **temporary, short-lived** animation that **guarantees** to
    perform its selector, even if the target has been released by all other owners.
*/
@property (nonatomic, strong) id strongTarget;

/// @name Configuring the Selector to be Performed

/**
 The selector to be performed when triggered.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the argument.
*/
@property (nonatomic, assign) SEL selector;

/**
 The argument passed to the selector when triggered.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the argument.
*/
@property (nonatomic, strong) id argument;

/// @name Triggering the Selector

/**
 The triggering method for the perform-selector object.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the argument.
*/
- (void)execute;

/**
 Returns an `SKAction` to trigger this perform-selector object.

 The action returned by

     [thisObject action]

 is equivalent to

     [SKAction performSelector:@selector(execute) onTarget:thisObject]
*/
- (SKAction *)action;

@end

/**
 A lightweight encodable object that, when triggered, can perform a selector on a
 strongly-retained target with two arguments.

 Intended as a replacement for `SKAction runBlock:`, which is more versatile, but which
 cannot be encoded.

 See `HLPerformSelectorStrongSingle` for documentation.
*/
@interface HLPerformSelectorStrongDouble : NSObject <NSCoding>

/// @name Creating a Perform-Selector Object

/**
 Initializes a perform-selector object with all properties.
*/
- (instancetype)initWithStrongTarget:(id)strongTarget selector:(SEL)selector argument1:(id)argument1 argument2:(id)argument2;

/**
 The target the selector will be performed on, when triggered.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the arguments.

 The target is retained strongly, despite the potential for retain cycles:

  - Typically, the target is a controller that is also the parent node of the child
    running the animation sequence.

  - The target, therefore, retains the child; the child retains its running `SKActions`;
    and the no-argument triggering `performSelector:onTarget:` retains this
    perform-selector object.

  - This perform-selector object retains the target, completing the cycle.  Such a cycle
    might be appropriate for a **temporary, short-lived** animation that **guarantees** to
    perform its selector, even if the target has been released by all other owners.
*/
@property (nonatomic, strong) id strongTarget;

/// @name Configuring the Selector to be Performed

/**
 The selector to be performed when triggered.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the arguments.
*/
@property (nonatomic, assign) SEL selector;

/**
 The first argument passed to the selector when triggered.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the arguments.
*/
@property (nonatomic, strong) id argument1;

/**
 The second argument passed to the selector when triggered.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the arguments.
*/
@property (nonatomic, strong) id argument2;

/// @name Triggering the Selector

/**
 The triggering method for the perform-selector object.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the arguments.
*/
- (void)execute;

/**
 Returns an `SKAction` to trigger this perform-selector object.

 The action returned by

     [thisObject action]

 is equivalent to

     [SKAction performSelector:@selector(execute) onTarget:thisObject]
*/
- (SKAction *)action;

@end

/**
 A lightweight encodable object that, when triggered, can perform a selector on a
 weakly-retained target with a single argument.

 Intended as a replacement for `SKAction runBlock:`, which is more versatile, but which
 cannot be encoded.

 See `HLPerformSelectorStrongSingle` for documentation.
*/
@interface HLPerformSelectorWeakSingle : NSObject <NSCoding>

/// @name Creating a Perform-Selector Object

/**
 Initializes a perform-selector object with all properties.
*/
- (instancetype)initWithWeakTarget:(id)weakTarget selector:(SEL)selector argument:(id)argument;

/**
 The target the selector will be performed on, when triggered.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the argument.

 The target is retained weakly:

  - Typically, the target is a controller that is also the parent node of the child
    running the animation sequence.

  - The target, therefore, retains the child; the child retains its running `SKActions`;
    and the no-argument triggering `performSelector:onTarget:` retains this
    perform-selector object.

  - This perform-selector object retains the target only weakly, to avoid a retain cycle.
*/
@property (nonatomic, weak) id weakTarget;

/// @name Configuring the Selector to be Performed

/**
 The selector to be performed when triggered.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the argument.
*/
@property (nonatomic, assign) SEL selector;

/**
 The argument passed to the selector when triggered.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the argument.
*/
@property (nonatomic, strong) id argument;

/// @name Triggering the Selector

/**
 The triggering method for the perform-selector object.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the argument.
*/
- (void)execute;

/**
 Returns an `SKAction` to trigger this perform-selector object.

 The action returned by

     [thisObject action]

 is equivalent to

     [SKAction performSelector:@selector(execute) onTarget:thisObject]
*/
- (SKAction *)action;

@end

/**
 A lightweight encodable object that, when triggered, can perform a selector on a
 weakly-retained target with two arguments.

 Intended as a replacement for `SKAction runBlock:`, which is more versatile, but which
 cannot be encoded.

 See `HLPerformSelectorStrongSingle` for documentation.
*/
@interface HLPerformSelectorWeakDouble : NSObject <NSCoding>

/// @name Creating a Perform-Selector Object

/**
 Initializes a perform-selector object with all properties.
*/
- (instancetype)initWithWeakTarget:(id)weakTarget selector:(SEL)selector argument1:(id)argument1 argument2:(id)argument2;

/**
 The target the selector will be performed on, when triggered.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the arguments.

 The target is retained strongly, despite the potential for retain cycles:

  - Typically, the target is a controller that is also the parent node of the child
    running the animation sequence.

  - The target, therefore, retains the child; the child retains its running `SKActions`;
    and the no-argument triggering `performSelector:onTarget:` retains this
    perform-selector object.

  - This perform-selector object retains the target only weakly, to avoid a retain cycle.
*/
@property (nonatomic, strong) id weakTarget;

/// @name Configuring the Selector to be Performed

/**
 The selector to be performed when triggered.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the arguments.
*/
@property (nonatomic, assign) SEL selector;

/**
 The first argument passed to the selector when triggered.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the arguments.
*/
@property (nonatomic, strong) id argument1;

/**
 The second argument passed to the selector when triggered.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the arguments.
*/
@property (nonatomic, strong) id argument2;

/// @name Triggering the Selector

/**
 The triggering method for the perform-selector object.

 When the perform-selector object is triggered by the `execute` method, it will invoke its
 selector on the target, passing the arguments.
*/
- (void)execute;

/**
 Returns an `SKAction` to trigger this perform-selector object.

 The action returned by

     [thisObject action]

 is equivalent to

     [SKAction performSelector:@selector(execute) onTarget:thisObject]
*/
- (SKAction *)action;

@end

/**
 Notifies all running custom actions that the a scene frame is updating.

 As a consequence, all running custom actions will perform their configured selectors.
 See class method `notifySceneDidUpdate` for a shorthand way to post this notification.
*/
FOUNDATION_EXPORT NSString * const HLCustomActionSceneDidUpdateNotification;

/**
 A lightweight encodable object that, when triggered, repeatedly performs a selector on a
 target over a duration.

 Intended as a replacement for `SKAction customActionWithDuration:actionBlock:`, which is
 more versatile, but which cannot be encoded.

 The owner must post notification `HLCustomActionSceneDidUpdateNotification` from her
 `SKScene update:` method (on the default notification center) so that all
 currently-running `HLCustomAction` objects will update.  This keeps custom actions
 synchronized with the application's frame rate.  Like this:

     [[NSNotificationCenter defaultCenter] postNotificationName:HLCustomActionSceneDidUpdateNotification
                                                         object:self
                                                       userInfo:nil];

 Or use class method `notifySceneDidUpdate` for convenience.

 See http://stackoverflow.com/q/35249269/1332415 for context.

 Details
 -------

 When the node hierarchy is encoded, as is common during application state preservation or
 a "game save", nodes running `SKAction` actions with code blocks must be handled
 specially, since the code blocks cannot be encoded.

 Use `HLCustomAction` rather than `customActionWithDuration:actionBlock:`.

   - The `HLCustomAction` is triggered by a companion `[SKAction
     performSelector:onTarget:]`, invoking a designated `execute` method.

   - When it is triggered, the `HLCustomAction` tracks its own elapsed time and, when
     notified of a new frame in the `SKScene`, periodically performs the selector on the
     target, passing it the node, the elapsed time, and the duration.

   - `HLCustomAction` conforms to `NSCoding`.  When running on a node, it will be encoded
     along with the node.  On decoding, it will continue running.  (The way it runs is
     determined by `SKNode runAction:`.  As noted below in "Limitations", decoded
     `SKAction` sequences are restarted by `runAction:`, so the custom action will restart
     from the beginning after decoding.)

 Duration is a problem.  A `customActionWithDuration:actionBlock:` has a duration, but the
 triggering `SKAction` for the `HLCustomAction` does not.  There are at least two
 considerations here:

   - If the triggering action is running in a sequence, any actions sequenced after the
     custom action need to wait for the full configured duration of the custom action.

   - Even if it's not running in a sequence, though: The node's `runAction:` method will
     retain actions as long as it thinks they are running.  This is important so that the
     action will be encoded along with the node.  The custom action should be retained by
     the node for the full configured duration of the custom action.

 Therefore, the triggering action should always be run in a group like this:

     [SKAction group:@[ [SKAction performSelector:@selector(execute) onTarget:aCustomAction],
                        [SKAction waitForDuration:thisObject.duration] ]]

 Use the method `action` for convience.

 Examples
 --------

 A tweening example using the non-encodable `customActionWithDuration:actionBlock:`.

       SKSpriteNode *redNode = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(100.0f, 100.0f)];
       SKAction *flashInAction = [SKAction customActionWithDuration:3.0 actionBlock:^(SKNode *node, CGFloat elapsedTime){
         CGFloat normalTime = (CGFloat)(elapsedTime / 3.0);
         CGFloat normalValue = BounceEaseOut(normalTime);
         node.alpha = (1.0f - normalValue);
       }];
       [redNode runAction:flashInAction];

 The same effect achieved in an encodable way:

        - (void)HL_flashInWithNode:(SKNode *)node elapsedTime:(CGFloat)elapsedTime duration:(NSTimeInterval)duration {
          CGFloat normalTime = (CGFloat)(elapsedTime / duration);
          CGFloat normalValue = BounceEaseOut(normalTime);
          node.alpha = (1.0f - normalValue);
        }

        - (void)HL_showFlashingRedNode {
          SKSpriteNode *redNode = [SKSpriteNode spriteNodeWithColor:[SKColor redColor] size:CGSizeMake(100.0f, 100.0f)];
          HLCustomAction *flashInAction = [[HLCustomAction alloc] initWithWeakTarget:self
                                                                            selector:@selector(HL_flashInWithNode:elapsedTime:duration:userData:)
                                                                                node:redNode
                                                                            duration:3.0
                                                                            userData:nil];
          [redNode runAction:flashInAction.action];
        }

 Limitations
 -----------

 Currently the custom action does not implement much `SKAction` functionality, including:

   - Timing modes and functions.

   - The ability to pause the custom action when the node is paused.

 Also, notifications are an awkward way to do updates.  Two alternate versions of this
 object have been attempted so far: One that used the `NSObject` runloop (that is, using
 `performSelector:`) to do periodic updates of the custom action, and one that forced the
 caller to make explicit calls to update the custom action (presumably from her `SKScene
 update:`).  Both alternates have their own problems.

 Special Considerations
 ----------------------

 When a node is encoded with a running (not yet completed) `SKAction`, and then decoded,
 it will restart the `SKAction` from the beginning.  This is standard SpriteKit behavior.

 The behavior can be surprising, though, when this perform-selector action is running in a
 sequence: Upon decoding, the entire sequence (if it is not yet completed) will restart
 from the beginning, and even if this perform-selector object was performed before
 preservation, it will perform again after restoration.

 See `HLSequence` for an alternative; upon decoding, it will not re-run parts of the
 sequence that have already completed.
*/
@interface HLCustomAction : NSObject <NSCoding>

/// @name Creating a Custom Action Object

/**
 Initializes a custom action object with all properties.
 */
- (instancetype)initWithWeakTarget:(id)weakTarget
                          selector:(SEL)selector
                              node:(SKNode *)node
                          duration:(NSTimeInterval)duration
                          userData:(id)userData;

/// @name Issuing Notifications to Running Custom Actions

/**
 Notifies all running custom actions that the a scene frame is updating.

 As a consequence, all running custom actions will perform their configured selectors.

 Equivalent to calling:

     [[NSNotificationCenter defaultCenter] postNotificationName:HLCustomActionSceneDidUpdateNotification
                                                         object:self
                                                       userInfo:nil];

 from a derived scene's `SKScene update:` method.
*/
+ (void)notifySceneDidUpdate;

/// @name Configuring the Custom Action

/**
 The target with the selector that will be repeatedly called by the custom action (to
 affect a node over a duration).

 The target is retained weakly to avoid retain cycles:

   - Typically, the target is a controller that is also the parent node of the child
     running the animation sequence.

   - The target, therefore, retains the child; the child retains its running `SKActions`;
     and running `SKAction` that triggers this custom action object retains this custom
     action object.

   - If this custom action object retained the target strongly, it would complete a retain
     cycle.

 A retain cycle like that would be fine for short-lived animations, but it seems a weak
 retention is more-generally useful.
*/
@property (nonatomic, weak) id weakTarget;

/**
 The selector to be performed repeatedly by the custom action (to affect a node over a
 duration).

 The selector must take four arguments: the configured node, the current elapsed time, the
 configured duration, and (arbitrary) user data.  (The `elapsedTime` and `duration`
 arguments have different types, corresponding to the different types used by
 `customActionWithDuration:actionBlock:`.)

     ^(SKNode *node, CGFloat elapsedTime, NSTimeInterval duration, id userData)
*/
@property (nonatomic, assign) SEL selector;

/**
 The node that will be passed to the selector invoked repeatedly by the custom action.
*/
@property (nonatomic, strong) SKNode *node;

/**
 The duration for the custom action.
*/
@property (nonatomic, assign) NSTimeInterval duration;

/**
 Optional, abitrary user data to be passed (repeatedly) to the selector.
*/
@property (nonatomic, strong) id userData;

/// @name Triggering the Custom Action

/**
 The triggering method for the custom action.

 When the custom action is triggered by the `execute` method, it will invoke its selector
 repeatedly on the target over the duration.
*/
- (void)execute;

/**
 Returns an `SKAction` to trigger this custom action object, grouped with a same-duration
 wait action.

 Use this version for convenience in an `SKAction` sequence that depends on
 total duration of the custom action.

 The action returned by

     [thisObject action]

 is equivalent to

     [SKAction group:@[ [SKAction performSelector:@selector(execute) onTarget:thisObject],
                        [SKAction waitForDuration:thisObject.duration] ]]
*/
- (SKAction *)action;

@end

/**
 A commonly-useful encodable user data object to use with `HLCustomAction`.

 A common use case for `HLCustomAction` is tweening between two values (whether position,
 alpha, scale, or something else), which can be tracked by this user data object.  In the
 following example, a user data object is provided to the custom action in order to track
 a start and end point for an overshooting slide.

     - (void)slideUpdate:(SKNode *)node
             elapsedTime:(CGFloat)elapsedTime
                duration:(NSTimeInterval)duration
                userData:(HLCustomActionEndPoints *)userData
     {
       CGFloat normalTime = (CGFloat)(elapsedTime / duration);
       CGFloat normalValue = BackStandardEaseInOut(normalTime);
       node.position = CGPointMake(userData.start * (1.0f - normalValue) + userData.finish * normalValue, 0.0f);
     }

     - (void)slideNode:(SKNode *)node
     {
       HLCustomActionEndPoints *slideUserData = [[HLCustomActionEndPoints alloc] init];
       slideUserData.start = node.position.x;
       slideUserData.finish = self.size.width / 2.0f;

       HLCustomAction *slideAction = [[HLCustomAction alloc] initWithWeakTarget:self
                                                                       selector:@selector(slideUpdate:elapsedTime:duration:userData:)
                                                                           node:node
                                                                       duration:2.0
                                                                       userData:slideUserData];
       [node runAction:slideAction.action];
     }
*/
@interface HLCustomActionEndPoints : NSObject <NSCoding>

@property (nonatomic, assign) CGFloat start;

@property (nonatomic, assign) CGFloat finish;

@end

/**
 A lightweight encodable object that, when triggered, can run a sequence of actions on a
 node.

 Intended as an alternative (or companion) to `SKAction sequence:`.  The important
 difference is this: When this action-sequence object is decoded, it will not re-run any
 of its actions that have already completed.

 See http://stackoverflow.com/q/36293846/1332415 for context.

 Details
 -------

 When a node is encoded with a running `SKAction`, and then decoded, it will restart the
 `SKAction` from the beginning.  This is standard SpriteKit behavior.

 The same behavior holds true for the sequence `SKAction`: upon decoding, if it has not
 yet completed, the entire sequence will restart from the beginning.  Any actions in the
 sequence that completed before encoding will be run again after decoding.

 Sometimes this behavior is undesirable.  It would be hard to rewrite all `SKAction` types
 so that they resumed without restarting, but consider the sequence as a special case.
 Would it possible to run a list of actions in a sequence such that, when each action in
 the sequence completes, it is marked as such, and not re-run after decoding?

 One possibility to that end is to split the sequence into a few independent
 subsequences.  As each subsequence completes, it will no longer be running, and so will
 not be encoded if the application is preserved.  For instance, an original sequence like
 this:

     [self runAction:[SKAction sequence:@[ [SKAction performSelector:@selector(doX) onTarget:self],
                                           [SKAction waitForDuration:10.0],
                                           [SKAction performSelector:@selector(doY) onTarget:self],
                                           [SKAction waitForDuration:1.0],
                                           [SKAction performSelector:@selector(doZ) onTarget:self] ]]];

 could be split like this:

     [self runAction:[SKAction sequence:@[ [SKAction performSelector:@selector(doX) onTarget:self] ]]];

     [self runAction:[SKAction sequence:@[ [SKAction waitForDuration:10.0],
                                           [SKAction performSelector:@selector(doY) onTarget:self] ]]];

     [self runAction:[SKAction sequence:@[ [SKAction waitForDuration:11.0],
                                           [SKAction performSelector:@selector(doZ) onTarget:self] ]]];

 No matter when the node is encoded, the methods `doX`, `doY`, and `doZ` will only be
 run once.

 Depending on the animation, though, the duration of the waits might seem weird.  For
 example, say the application is preserved after `doX` and `doY` have run, during the
 1-second delay before `doZ`.  Then, upon restoration, the application won't run `doX` or
 `doY` again, but it will wait 11 seconds before running `doZ`.

 To avoid the perhaps-strange delays, split the sequence into a chain of dependent
 subsequences, each of which triggers the next one.  For the example, the split might
 look like this:

     - (void)doX
     {
       // do X...
       [self runAction:[SKAction sequence:@[ [SKAction waitForDuration:10.0],
                                             [SKAction performSelector:@selector(doY) onTarget:self] ]]];
     }

     - (void)doY
     {
       // do Y...
       [self runAction:[SKAction sequence:@[ [SKAction waitForDuration:1.0],
                                             [SKAction performSelector:@selector(doZ) onTarget:self] ]]];
     }

     - (void)doZ
     {
       // do Z...
     }

     - (void)runAnimationSequence
     {
       [self runAction:[SKAction performSelector:@selector(doX) onTarget:self]];
     }

 With this implementation, if the sequence is preserved after `doX` and `doY` have run,
 then, upon restoration, the delay before `doZ` will be only 1 second.  Sure, it's a full
 second (even if it was half elapsed before encoding), but the result is fairly
 understandable: Whatever action in the sequence was in progress at the time of encoding
 will restart, but once it completes, it is done.

 `HLSequence` is an abstracted version of the described concept.

 Special Considerations
 ----------------------

 Should actions in the sequence still be retained once they have completed?  There seems
 no reason to, except perhaps that this object is trying to imitate `SKAction sequence`,
 which **does** retain them for the lifetime of the sequence.  And users might be
 accustomed to such behavior; for instance, `HLCustomAction` depends on it.  So, for now,
 actions in the sequence will be retained for the lifetime of the `HLSequence`.

 Another consideration: Nesting this sequence with other groups and sequences will be
 problematic.  The timing will be probably be off: The triggering action for the
 `HLSequence` has no duration, and anyway, if this `HLSequence` is running in parallel to
 a `SKAction sequence` (or a `SKAction waitForDuration:`), and both are encoded, they will
 be out of sync on decoding.
*/
@interface HLSequence : NSObject <NSCoding>

/// @name Creating a Sequence

/**
 Initializes a sequence with all properties.
*/
- (instancetype)initWithNode:(SKNode *)node actions:(NSArray *)actions;

/// @name Configuring the Sequence

/**
 The node on which to run the actions of the sequence.

 The node is retained weakly because the node will be running the action subsequences for
 this sequence, which means it will retain this object strongly (since every subsequence
 but the last refers back to this object).  Retaining the node strongly would create a
 retain cycle, and would cause the sequence to keep running on the object even when no one
 else cared about the node anymore.

 It would be strange to change this node after initialization, but it would not cause any
 errors, and so the property allows writes.
*/
@property (nonatomic, weak) SKNode *node;

/**
 The actions to run on the node, when this sequence is triggered.

 Note that the actions are retained by this object even when they have completed.  See
 note in header.
*/
@property (nonatomic, readonly) NSArray *actions;

/// @name Triggering the Sequence

/**
 The triggering method for the sequence.

 When the sequence is triggered by the `execute` method, it will run its actions (one at a
 time in order) on the configured node.
*/
- (void)execute;

/**
 Returns an `SKAction` to trigger this sequence.

 The action returned by

     [thisObject action]

 is equivalent to

     [SKAction performSelector:@selector(execute) onTarget:thisObject]

 Note that, as in `HLCustomAction`, this triggering action has no duration, even though
 the triggered sequence of actions (probably) does.  For `HLSequence`, unlike
 `HLCustomAction`, the owner probably doesn't care and won't notice.  If the caller does
 care, she's on her own to pad out the triggering action with a corresponding wait.  See
 header notes ("Special Considerations") for a discussion of related problems.
*/
- (SKAction *)action;

@end
