//
//  HLGestureTarget.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 2/4/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>
typedef UIGestureRecognizer HLGestureRecognizer;

#else

#import <Cocoa/Cocoa.h>
// note: Contains a class category on NSGestureRecognizer required for gesture target to
// work under macOS.
#import "NSGestureRecognizer+MultipleActions.h"
typedef NSGestureRecognizer HLGestureRecognizer;

#endif

/**
 Returns true if the passed gesture recognizers are of the same type and are configured in
 an equivalent way (dependent on class).

 For example, if the two passed gesture recognizers are both `UITapGestureRecognizers`
 configured with the same number of required taps and touches, then this method will
 return `YES`.

 Use case: Gesture targets return a list of gesture recognizers to which they might add
 themselves.  It is then the responsibility of the gesture recognizer delegate (usually an
 `SKScene` or view controller) to add gesture recognizers to the view.  But if the
 delegate already has an equivalent gesture recognizer added, then there's no need to add
 another.  This method can be used to decide what counts as "equivalent".

 @bug Might be worth comparing and contrasting with `[UIGestureTarget isEqual:]`.
*/
BOOL HLGestureTarget_areEquivalentGestureRecognizers(HLGestureRecognizer *a, HLGestureRecognizer *b);

/**
 A generic target for gesture recognizers.

 "Gesture recognizer" refers under iOS to `UIGestureRecognizer` and under macOS to
 `NSGestureRecognizer`.

 ## Usage

 A single delegate for a bunch of gesture recognizers creates and maintains the
 recognizers, but wants to forward the gesture to different targets based on where the
 gesture starts.  An example might be an `SKScene`, which has only a single view (and
 hence only a single set of gesture recognizers), but perhaps many different `SKNode`
 components within the scene, like a world, a character, or a toolbar.  Upon receiving the
 initial location of a particular gesture, the `SKScene` finds likely `HLGestureTarget`
 components and offers them the chance to become targets of that gesture.  See `HLScene`
 for a simple implementation.

 Note that `HLGestureTarget` is a protocol.  This allows a number of implementation
 patterns:

 1. A small scene might be the gesture target for all its components.  (This is pretty
    much the same as having the gesture delegate, that is, the scene, do all the gesture
    handling also; the small advantage would be a natural way to split handling methods by
    topic, for instance `handleWorldTap:` and `handleToolbarTap:`.)

 2. A scene's functionality might be split out into custom `SKNode` subclasses; in that
    case, each custom node might be its own gesture target and do its own gesture
    handling.

 3. A scene (or custom `SKNode` subclass) might create a default `SKNode` instance,
    without subclassing, and can configure it for simple gesture interaction by attaching
    an out-of-the-box `HLGestureTarget` using `[SKNode+HLGestureTarget
    hlSetGestureTarget]`.  For example:

        SKSpriteNode *myButton = [SKSpriteNode spriteNodeWith...];
        [myButton hlSetGestureTarget:[[HLTapGestureTarget alloc] initWithHandleGestureBlock:^{
            NSLog(@"tapped button");
        }]];

 ## Ad Hoc Gesture Targets: Benefits and Dangers

 Implementation (3), above, describes a usage pattern that allows ad hoc creation of
 interactive nodes, without subclassing.

 It can be nice to do this for a simple one-off popup: a message, perhaps, or an extremely
 simple configuration dialog.

 Say I want to create a popup message with a single Done button, in an ad hoc fashion.
 Easy.  (I'm leaving out the sizing and positioning code so it doesn't distract from the
 logic.)

     SKSpriteNode *alertNode = [SKSpriteNode spriteNodeWithColor:[SKColor blueColor] size:CGSizeMake(200.0f, 180.0f)];

     HLMultilineLabelNode *labelNode = [[HLMultilineLabelNode alloc] initWithFontNamed:@"Helvetica"];
     labelNode.text = @"Something happened, and you should know about it.";

     HLLabelButtonNode *doneButton = [[HLLabelButtonNode alloc] initWithColor:[SKColor blackColor] size:CGSizeMake(80.0f, 40.0f)];
     doneButton.text = @"Done";

     [alertNode addChild:labelNode];
     [alertNode addChild:doneButton];

     __weak SKSpriteNode *alertNodeWeak = alertNode;
     [doneButton hlSetGestureTarget:[HLTapGestureTarget tapGestureTargetWithHandleGestureBlock:^(UIGestureRecognizer *gestureRecognizer){
       [alertNodeWeak removeFromParent];
     }]];
     [self needSharedGestureRecognizersForNode:doneButton];

     [self addChild:alertNode];

 But already it's a bit of a pain setting up the tap gesture block with a weak reference
 (in order to avoid a retain cycle on `alertNode`).  And it can quickly get much more
 complicated when there is more to do in the block: for instance, reading user input
 values from the dialog, or having separate "Okay" and "Cancel" buttons.

 Anyway, the point is: `HLSpriteKit` allows ad hoc gesture targets, which is nice, but in
 many instances subclassing (or at least delegation) makes things much simpler and easier
 to understand.
*/
@protocol HLGestureTarget <NSObject>

/// @name Adding to Gesture Recognizers

/**
 Adds itself (as target of an action) to the passed gesture recognizer if it is interested
 in the particular gesture at the given location (in scene coordinates).

 Returns `YES` if added; this helps the caller determine if any of its targets care about
 the gesture.  The target adds itself with a call like this:

     [gestureRecognizer addTarget:self action:@selector(handleTap:)];

 The implementation of this method should assume that it is not already added as a target
 to the gesture recognizer.  (It is typical for the caller to clear all targets from the
 gesture recognizer before then offering it to be claimed by one or more of its possible
 targets for the given location.)

 Returns an additional boolean indicating whether the gesture was absorbed by the target.
 The typical value is `YES`: For example, a tap on a button should be "absorbed" so that
 it gets handled only by the button, and not by another gesture target behind the
 button.  And in fact it's often set to `YES` even if the gesture target did *not* want to
 add itself to the gesture recognizer: That same button will probably absorb a swipe
 gesture that starts on the button.  But other examples abound:

 - A set of buttons which has space between buttons.  Hit-testing by SpriteKit's
   `nodesAtPoint` uses `calculateAccumulatedFrame`, and so (depending on what hit-testing
   is used by the caller) probably the spaces will still count as part of the target.  If
   the gesture is in the space between buttons, the target's `addToGesture` method should
   return `NO` (because it did not add itself to the gesture recognizer).  Setting
   `didAbsorbGesture` could go either way: perhaps a pan gesture starting between buttons
   should pan the world below the buttons (`didAbsorbGesture` set to `NO`); or maybe a tap
   between buttons should not fall through, since the player probably meant to tap a
   button and just missed (`didAbsorbGesture` set to `YES`).

 - An elf and a house on a pannable world node.  A pan on the elf should move the elf
   around the world: so `addToGesture` should return `YES` and set `didAbsorbGesture` to
   `YES` so that the world won't pan.  But the house is only tappable, not pannable.  So a
   tap gesture on the house would be handled by the house's `addToGesture`, but a pan on
   the house would return `NO` and set `didAbsorbGesture` to `NO`.

 - A more-or-less modal game menu overlay on top of a pannable world node.  The overlay is
   not itself pannable, but it should absorb all gestures and prevent them from getting
   handled by the scene underneath.  Even if the big backdrop node of the overlay is not
   already a gesture target, it should become one, in order just to set `didAbsorbGesture`
   to `YES` for all gestures.

 This method is designed to work with `HLScene`, which has an implementation of "the
 caller" (mentioned only generically above).  A typical implementation will have a
 collection of gesture recognizers for which it serves as delegate.  On first recognition
 of a gesture recognizer (`gestureRecognizer:shouldRecieveTouch:` in iOS or
 `gestureRecognizer:shouldAttemptToRecognizeWith:` in macOS), the caller might use
 bounding box (`[SKNode containsPoint]`) or other hit testing (maybe `nodeAtPoint`) to
 find the topmost possibly-relevant target, and ask it to add itself to the gesture if
 it's interested, offering the gesture to the target's node tree parents until it is
 absorbed.
*/
- (BOOL)addToGesture:(HLGestureRecognizer *)gestureRecognizer
       firstLocation:(CGPoint)sceneLocation
    didAbsorbGesture:(BOOL *)didAbsorbGesture;

/**
 Returns an array of configured gesture recognizers that the target wants to handle.

 These are used by the caller to initialize and configure itself (usually by attaching the
 gesture recognizers, or equivalent ones, to its view).
*/
- (NSArray *)addsToGestureRecognizers;

@end

#if TARGET_OS_IPHONE

@protocol HLTapGestureTargetDelegate;

/**
 An externally-configurable gesture target which only adds to the tap gesture recognizer.
 When a tap is recognized, it is forwarded to an owner-provided delegate or handling
 block.

 Delegation might be preferred for two reasons:

 * The block is not encodable, but the delegate is.  (The block must be reset on decode.)

 * The block is more susceptible to retain cycles.
*/
@interface HLTapGestureTarget : NSObject <HLGestureTarget, NSCoding, NSCopying>

/// @name Creating a Tap Gesture Target

/**
 Initializes a tap gesture target with the passed delegate.
*/
- (instancetype)initWithDelegate:(id <HLTapGestureTargetDelegate>)delegate;

/**
 Initializes a tap gesture target with the passed handle gesture block.
*/
- (instancetype)initWithHandleGestureBlock:(void(^)(HLGestureRecognizer *))handleGestureBlock;

/**
 Initializes a tap gesture target with the passed gesture-handling (weak) target and
 selector.

 See `setWeakTarget:selector:` for details on the required selector signature.
*/
- (instancetype)initWithHandleGestureWeakTarget:(id)weakTarget selector:(SEL)selector;

/**
 Convenience method for instantiating a tap gesture target configured with the passed
 delegate.

 See `initWithDelegate:`.
*/
+ (instancetype)tapGestureTargetWithDelegate:(id <HLTapGestureTargetDelegate>)delegate;

/**
 Convenience method for instantiating a tap gesture target configured with the passed
 handle gesture block.

 See `initWithHandleGestureBlock:`.
*/
+ (instancetype)tapGestureTargetWithHandleGestureBlock:(void(^)(HLGestureRecognizer *))handleGestureBlock;

/**
 Convenience method for instantiating a tap gesture target configured with the passed
 gesture-handling (weak) target and selector.

 See `initWithHandleGestureWeakTarget:selector:`.
*/
+ (instancetype)tapGestureTargetWithHandleGestureWeakTarget:(id)weakTarget selector:(SEL)selector;

/// @name Setting the Delegate or Handler

/**
 A delegate that will be called when the gesture target is tapped.

 See `HLTapGestureTargetDelegate`.
*/
@property (nonatomic, weak) id <HLTapGestureTargetDelegate> delegate;

/**
 A block that will be executed when the gesture target is tapped.

 Beware retain cycles when using the callback to invoke a method on the node that owns
 this gesture target.  A common example is creating a node that dismisses itself when
 tapped:

     [myNode hlSetGestureTarget:[HLTapGestureTarget tapGestureTargetWithHandleGestureBlock:^(UIGestureRecognizer *gestureRecognizer){
       [myNode removeFromParent];
     }]];

 In the example, `myNode` retains its gesture target, which has a block retaining
 `myNode`.  This can be rewritten to retain the node weakly:

     __weak SKNode *myNodeWeak = myNode;
     [myNode hlSetGestureTarget:[HLTapGestureTarget tapGestureTargetWithHandleGestureBlock:^(UIGestureRecognizer *gestureRecognizer){
       [myNodeWeak removeFromParent];
     }]];

 If the weak reference is mentioned more than once, then it might need to be made strong
 again inside the block:

     __weak SKNode *myNodeWeak = myNode;
     [myNode hlSetGestureTarget:[HLTapGestureTarget tapGestureTargetWithHandleGestureBlock:^(UIGestureRecognizer *gestureRecognizer){
       SKNode *myNodeStrongAgain = myNodeWeak;
       if (myNodeStrongAgain.parent) {
         [myNodeStrongAgain removeFromParent];
       }
     }]];

 An easier way to avoid retain cycles is to use the delegate or selector interface of
 `HLTapGestureTarget`; see `delegate` or `setHandleGestureWeakTarget:selector:`.
*/
@property (nonatomic, strong) void (^handleGestureBlock)(HLGestureRecognizer *);

/**
 A selector that will be performed on the target (retained weakly) when the gesture
 target is tapped.

 The selector must take one parameter: the gesture recognizer.
*/
- (void)setHandleGestureWeakTarget:(id)weakTarget selector:(SEL)selector;

@end

@protocol HLTapGestureTargetDelegate <NSObject>

- (void)tapGestureTarget:(HLTapGestureTarget *)tapGestureTarget didTap:(HLGestureRecognizer *)gestureRecognizer;

@end

#else

@protocol HLClickGestureTargetDelegate;

/**
 An externally-configurable gesture target which only adds to the click gesture recognizer.
 When a click is recognized, it is forwarded to an owner-provided delegate or handling
 block.

 Delegation is preferred for two reasons:

 * The block is not encodable, but the delegate is.  (The block must be reset on decode.)

 * The block is more susceptible to retain cycles.
*/
@interface HLClickGestureTarget : NSObject <HLGestureTarget, NSCoding, NSCopying>

/// @name Creating a Click Gesture Target

/**
 Initializes a click gesture target with the passed delegate.
*/
- (instancetype)initWithDelegate:(id <HLClickGestureTargetDelegate>)delegate;

/**
 Initializes a click gesture target with the passed handle gesture block.
*/
- (instancetype)initWithHandleGestureBlock:(void(^)(HLGestureRecognizer *))handleGestureBlock;

/**
 Initializes a click gesture target with the passed gesture-handling (weak) target and
 selector.

 See `setWeakTarget:selector:` for details on the required selector signature.
*/
- (instancetype)initWithHandleGestureWeakTarget:(id)weakTarget selector:(SEL)selector;

/**
 Convenience method for instantiating a click gesture target configured with the passed
 delegate.

 See `initWithDelegate:`.
*/
+ (instancetype)clickGestureTargetWithDelegate:(id <HLClickGestureTargetDelegate>)delegate;

/**
 Convenience method for instantiating a click gesture target configured with the passed
 handle gesture block.

 See `initWithHandleGestureBlock:`.
*/
+ (instancetype)clickGestureTargetWithHandleGestureBlock:(void(^)(HLGestureRecognizer *))handleGestureBlock;

/**
 Convenience method for instantiating a click gesture target configured with the passed
 gesture-handling (weak) target and selector.

 See `initWithHandleGestureWeakTarget:selector:`.
*/
+ (instancetype)clickGestureTargetWithHandleGestureWeakTarget:(id)weakTarget selector:(SEL)selector;

/// @name Setting the Delegate or Handler

/**
 A delegate that will be called when the gesture target is clicked.

 See `HLClickGestureTargetDelegate`.
*/
@property (nonatomic, weak) id <HLClickGestureTargetDelegate> delegate;

/**
 A block that will be executed when the gesture target is clicked.
*/
@property (nonatomic, strong) void (^handleGestureBlock)(HLGestureRecognizer *);

@end

@protocol HLClickGestureTargetDelegate <NSObject>

- (void)clickGestureTarget:(HLClickGestureTarget *)clickGestureTarget didClick:(HLGestureRecognizer *)gestureRecognizer;

@end

#endif
