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

  - Typically, the target is a controller which is also the parent node of the child
    running the animation sequence.

  - The target, therefore, retains the child; the child retains its running `SKActions`;
    and the no-argument triggering `performSelector:onTarget:` retains this
    perform-selector object.

  - This perform-selector object retains the target, completing the cycle.  Such a cycle
    might be appropriate for a **temporary, short-lived** animation which **guarantees**
    to perform its selector, even if the target has been released by all other owners.
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

  - Typically, the target is a controller which is also the parent node of the child
    running the animation sequence.

  - The target, therefore, retains the child; the child retains its running `SKActions`;
    and the no-argument triggering `performSelector:onTarget:` retains this
    perform-selector object.

  - This perform-selector object retains the target, completing the cycle.  Such a cycle
    might be appropriate for a **temporary, short-lived** animation which **guarantees**
    to perform its selector, even if the target has been released by all other owners.
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

  - Typically, the target is a controller which is also the parent node of the child
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

  - Typically, the target is a controller which is also the parent node of the child
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
          HLCustomAction *flashInAction = [[HLCustomAction alloc] initWithWeakTarget:self selector:@selector(HL_flashInWithNode:elapsedTime:duration:) node:redNode duration:3.0 typicalInterval:(1.0 / 60.0)];
          [redNode runAction:flashInAction.action];
        }

 Limitations
 -----------

 Currently the custom action does not implement much `SKAction` functionality, including:

   - Timing modes and functions.

   - The ability to pause the custom action when the node is paused.

 One more issue.  As documented on this StackOverflow question
 <http://stackoverflow.com/q/36293846/1332415>: When a node is encoded with a running
 SKAction sequence, and then decoded, it will run the entire sequence from the beginning.
 The whole idea of encoding a sequence including a custom action is conditioned on the
 desired behavior: Do you really want your sequence to restart from the beginning when it
 is decoded?  That's apparently the standard SpriteKit behavior, though, and so it is
 faithfully followed here.

 Also, notifications are an awkward way to do updates.  Two alternate versions of this
 object have been attempted so far: One that used the `NSObject` runloop (that is, using
 `performSelector:`) to do periodic updates of the custom action, and one that forced the
 caller to make explicit calls to update the custom action (presumably from her `SKScene
 update:`).  Both alternates have their own problems.
*/
@interface HLCustomAction : NSObject <NSCoding>

/// @name Creating a Custom Action Object

/**
 Initializes a custom action object with all properties.
 */
- (instancetype)initWithWeakTarget:(id)weakTarget
                          selector:(SEL)selector
                              node:(SKNode *)node
                          duration:(NSTimeInterval)duration;

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

   - Typically, the target is a controller which is also the parent node of the child
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

 The selector must take three arguments: the configurednode, the current elapsed time, and
 the configured duration.  (The `elapsedTime` and `duration` arguments have different
 types, corresponding to the different types used by
 `customActionWithDuration:actionBlock:`.)

     ^(SKNode *node, CGFloat elapsedTime, NSTimeInterval duration)
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
