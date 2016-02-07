//
//  HLAction.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 2/4/16.
//  Copyright (c) 2016 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

/**
 A lightweight encodable object that, when triggered, can perform a selector on a target
 with an argument.

 Intended as a replacement for `SKAction runBlock:`, which is more versatile, but which
 cannot be encoded.

 See http://stackoverflow.com/q/35249269/1332415 for context.

 When the node hierarchy is encoded, as is common during application state preservation or
 a “game save”, nodes running `SKAction` actions with code blocks must be handled
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

 Instead, use `HLPerformSelector`.

   - The caller instantiates the `HLPerformSelector` object and sets its properties:
     target, selector, and arguments.

   - The `HLPerformSelector` is triggered in a `runAction` animation by the standard
     no-argument `[SKAction performSelector:onTarget:]`.  For this triggering action, the
     target is the `HLPerformSelector` object and the selector is a designated `execute`
     method.

   - `HLPerformSelector` conforms to `NSCoding`.

   - As a bonus, the triggering `SKAction` retains a strong reference to the
     `HLPerformSelector`, and so both will be encoded along with the node running the
     actions.

   - A version of `HLPerformSelector` could be made that retains the target weakly, which
     might be nice and/or necessary.

 Usage Example

     SKAction *fadeAction = [SKAction fadeOutWithDuration:3.0];
     SKAction *removeAction = [SKAction removeFromParent];
     HLPerformSelector *cleanupCaller = [[HLPerformSelector alloc] initWithTarget:self selector:@selector(orcDidFinishDying:) argument:orcNode];
     SKAction *cleanupAction = [SKAction performSelector:@selector(execute) onTarget:cleanupCaller];
     [orcNode runAction:[SKAction sequence:@[ fadeAction, removeAction, cleanupAction ]]];
 */
@interface HLPerformSelector : NSObject <NSCoding>

- (instancetype)initWithTarget:(id)target selector:(SEL)selector argument:(id)argument;

@property (nonatomic, strong) id target;

@property (nonatomic, assign) SEL selector;

@property (nonatomic, strong) id argument;

- (void)execute;

@end

/**
 A lightweight encodable object that, when triggered, repeatedly performs a selector on
 a target over a duration.

 Intended as a replacement for `SKAction customActionWithDuration:actionBlock:`, which is
 more versatile, but which cannot be encoded.

 See http://stackoverflow.com/q/35249269/1332415 for context.

 When the node hierarchy is encoded, as is common during application state preservation or
 a “game save”, nodes running `SKAction` actions with code blocks must be handled
 specially, since the code blocks cannot be encoded.

 Use `HLCustomAction` rather than `customActionWithDuration:actionBlock:`.

   - The `HLCustomAction` is triggered by the no-argument `[SKAction
     performSelector:onTarget:]`, invoking a designated `execute` method.

   - A `customActionWithDuration:actionBlock:` has a duration.  But the triggering
     `performSelector:onTarget:` does not.  The caller must insert a companion
     `waitForDuration:` action into her sequence if it depends on duration.

   - The `HLCustomAction` is initialized with a target, selector, node, and duration.

   - When it is triggered, the `HLCustomAction` tracks its own elapsed time and
     periodically calls the selector on the target, passing it the node and the elapsed
     time.

   - `HLCustomAction` conforms to `NSCoding`.  On decoding, if already triggered, it
     resumes calling the selector for the remainder of its configured duration.
 */
// TODO: Implement.
//@interface HLCustomAction : NSObject <NSCoding>
//
//- (instancetype)initWithTarget:(id)target selector:(SEL)selector node:(SKNode *)node duration:(NSTimeInterval)duration;
//
//@property (nonatomic, strong) id target;
//
//@property (nonatomic, assign) SEL selector;
//
//@property (nonatomic, strong) SKNode *node;
//
//@property (nonatomic, assign) NSTimeInterval duration;
//
//- (void)execute;
//
//@end
