//
//  HLGestureTarget.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 2/4/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 Returns true if the passed gesture recognizers are of the same type and are configured
 in an equivalent way (dependent on class).

 For example, if the two passed gesture recognizers are both `UITapGestureRecognizers`
 configured with the same number of required taps and touches, then this method will
 return `YES`.

 Use case: Gesture targets return a list of gesture recognizers to which they might
 add themselves.  It is then the responsibility of the `UIGestureRecognizer` delegate
 (usually an `SKScene` or `UIViewController`) to add gesture recognizers to the view.
 But if the delegate already has an equivalent gesture recognizer added, then there's
 no need to add another.  This method can be used to decide what counts as "equivalent".

 @bug Might be worth comparing and contrasting with `[UIGestureTarget isEqual:]`.
*/
BOOL HLGestureTarget_areEquivalentGestureRecognizers(UIGestureRecognizer *a, UIGestureRecognizer *b);

/**
 A generic target for `UIGestureRecognizers`.

 ## Use Case

 A single delegate for a bunch of gesture recognizers creates and maintains the
 recognizers, but wants to forward the gesture to different targets based on where the
 gesture starts.  An example might be an `SKScene`, which has only a single view (and
 hence only a single set of gesture recognizers), but perhaps many different `SKNode`
 components within the scene, like a world, a character, or a toolbar.  Upon receiving the
 first touch of a particular gesture, the `SKScene` finds likely `HLGestureTarget`
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
*/
@protocol HLGestureTarget <NSObject>

/// @name Adding to Gesture Recognizers

/**
 Adds itself (as target of an action) to the passed gesture recognizer if it is interested
 in the particular gesture and first-touch location.

 Returns `YES` if added; this helps the caller determine if any of its targets care about
 the gesture.  The target adds itself with a call like this:

     [gestureRecognizer addTarget:self action:@selector(handleTap:)];

 The implementation of this method should assume that it is not already added as a target
 to the gesture recognizer.  (It is typical for the caller to clear all targets from the
 gesture recognizer before then offering it to be claimed by one or more of its possible
 targets for the given first touch.)

 Returns an additional boolean indicating whether the touch location is "inside" the
 target (regardless of whether the target added itself to the gesture recognizer).  This
 value is important so that the caller can decide whether or not to offer the gesture and
 touch to other targets.  A common example is a button target given a pan starting inside
 the button: The button does not care about pans, and so does not add itself as a target
 to the gesture, but it returns `isInside` `YES`, so the caller knows that the pan should
 probably not fall through to other targets.  (This could be separated out as a separate
 method in `HLGestureTarget`, but the logic is often computationally redundant with the
 decision to add self as target.)  (Also, as an motivating example: If all targets were
 `SKNode`s and the caller could use `containsPoint` to determine whether a gesture first
 touch was "inside" a particular target, then the target wouldn't have to weigh in.  But
 clearly a hit test inside a bounding box is not always sufficient; it depends on the
 target.)  Typically, all touches passed to a gesture target's
 `addToGesture:firstTouch:isInside:` method can be assumed to be inside the target
 (because of the caller's logic), unless the touch falls into some space of the target
 which is considered invisible (from a user's point of view).

 To explain the logic, here is a sketch of a typical caller implementation.  The caller is
 a `UIGestureRecognizerDelegate` of a number of standard gesture recognizers.  It has a
 number of possible targets for the gestures, some of which are controlled completely by
 the caller, and some of which are encapsulated into opaque components.  The motivating
 example is reusable subclasses of `SKNode`, which can't own their own gesture
 recognizers, since they aren't `UIViews`.  On first touch of a gesture recognizer
 (`gestureRecognizer:shouldRecieveTouch:`), the caller might use bounding box
 (e.g. `[SKNode containsPoint]`) or other hit testing (e.g. `[SKNode nodeAtPoint]`) to
 find possibly-relevant targets, and then query them in order of visible layer height
 (e.g. `[SKNode zPosition]`): each target is asked to add itself to the gesture if it's
 interested.  A caller might decide to only offer the gesture to the first target that
 claims the gesture's first touch is "inside"; or, it might decide to offer the gesture to
 all targets at a location regardless of layer height and opacity.
*/
- (BOOL)addToGesture:(UIGestureRecognizer *)gestureRecognizer firstTouch:(UITouch *)touch isInside:(BOOL *)isInside;

// Commented out: Another idea, for callers with lots of targets: A version of
// addToGesture to be implemented by SKNode descendents who care about sceneLocation not
// touch.  This could avoid every target doing the same coordinates conversion over and
// over.
//- (BOOL)addToGesture:(UIGestureRecognizer *)gestureRecognizer firstTouchSceneLocation:(CGPoint)sceneLocation isInside:(BOOL *)isInside;

/**
 Returns an array of configured gesture recognizers that the target wants to handle.

 These are used by the caller to initialize and configure itself (usually by attaching
 the gesture recognizers, or equivalent ones, to its view).

 Some callers might also be able to use these to avoid unnecessary calls to `addToGesture`
 (which is assumed to be more costly), but typically not: A target still must evaluate "is
 inside" for all gestures, even if it doesn't handle some of those gestures.
*/
- (NSArray *)addsToGestureRecognizers;

@end

/**
 An externally-configurable gesture target which only adds to the (single) tap gesture
 recognizer.  When a tap is recognized, it is forwarded to an owner-provided handling
 block.

 The handling block is not encodable, so the caller will have to reset it on decode.

 @bug Consider making a version of this (or extension of this) which itself uses
      delegation for the call to handle the gesture, rather than a block; the delegate
      pointer, then, would be encodable.
*/
@interface HLTapGestureTarget : NSObject <HLGestureTarget, NSCoding, NSCopying>

/// @name Creating a Tap Gesture Target

/**
 Convenience method for instantiating a tap gesture target configured with the passed
 handle gesture block.

 See `initWithHandleGestureBlock:`.
*/
+ (instancetype)tapGestureTargetWithHandleGestureBlock:(void(^)(UIGestureRecognizer *))handleGestureBlock;

/**
 Initializes a tap gesture target with the passed handle gesture block.
*/
- (instancetype)initWithHandleGestureBlock:(void(^)(UIGestureRecognizer *))handleGestureBlock;

/// @name Handling Gestures

/**
 A block that is executed when a tap gesture is handled.
*/
@property (nonatomic, copy) void (^handleGestureBlock)(UIGestureRecognizer *);

/**
 Whether or not unhandled gestures are considered "isInside" the gesture target.

 If `NO`, then typically the gesture recognizer delegate will not allow any gesture inside
 the target to "fall through" to gesture targets below this one.  Default value is `NO`.
*/
@property (nonatomic, assign, getter=isGestureTransparent) BOOL gestureTransparent;

@end

/**
 noob: So in an HLScene I was working on, I had a method for creating a modal
 presentation consisting of a number of nodes which I created on-demand in the scene
 without using any custom node subclassing.  I used a bit SKSpriteNode in the background
 with an HLTapGestureTarget to handle taps, which would dismiss the modal presentation;
 also, another SKSpriteNode button (again with an HLTapGestureTarget) did the same
 thing, but with a special function (go to the next level of the game).  I did it
 without creating a dismissal callback in the scene, so then all nodes and behavior was
 configured once at setup, and then displayed, with no other state necessary in the
 scene.

 So...it's pretty messy, because the cleanup needs to be exremely careful about retain
 cycles.  Furthermore, it gets more complicated when there are multiple gesture targets
 on the modal presentation: For example, each of them needs to unregister themselves and
 *all* the others from the HLScene.  Nasty.

 Here were my thoughts (before I eventually went ahead and subclassed):

  1) The buttons need to be aware of each other.  Perhaps like the "Okay" and "Cancel"
     buttons of an alert, all actions should pass through the same callback.  In that
     case, the owner has an FL_goalsDismissWithButtonIndex method, with stored
     goalsOverlay state from this method, and set each of their handleGestureBlocks to
     call it.  But that seems to be getting closer and closer to subclassing: The
     buttons are acting together, with shared state, and so should be entirely
     encapsulated together.

  2) But really, the only reason the buttons need to be aware of each other is
     (currently) because of unregistering: they both need to unregister both (when
     dismissing the overlay).  Which reminds me that unregistering HLGestureTargets is a
     pain in the ass in general, and according to current implementation not even
     essential.  BUT.  Unregistering still makes sense for other possible future HLScene
     implementations, and no matter what, unregistering is a nice option to have (even
     just to clear userData) and so it philosophically makes sense to always do it.

  3) Unregistering is especially a pain in the ass when the HLTapGestureTarget wants to
     unregister its owner node: The node contains a reference to the handleGesture
     block, but then we try to make the block contain a reference to the node.  To break
     the retain cycle, we can make the node reference weak, but that's just one more
     line of code in something that already feels unnecessary.  Can there be
     functionality somewhere which automatically unregisters a node when the node is
     deallocated?

  4) And in fact the real problem is HLGestureTarget nodes that don't just want to
     unregister but in fact want to delete themselves.  Very common: Create some kind of
     dialog box, and add a single button which dismisses it.  So then the button removes
     the dialog box from the node hierarchy, no other references exist, the parent is
     deleted which deletes the children, the button is deleted, so the callback block
     (being run) is deleted.  So (see notes in notes/objective-c.txt) we have add TWO
     lines of code, making a strong reference (at block execution time) of a weak
     reference (at block copy time) of the dialog box.  What a pain.  HLGestureTarget
     should make this easier for us somehow.  Could it retain a strong reference for us
     right before invoking the block?

 For now: Consider it normal that, when building a node with multiple out-of-the-box
 HLGestureTargets, you have to set their handleGesture callbacks all at the same time at
 the bottom of the setup code, with full awareness of each other.

 The code evolved as far as this before I subclassed:

     __weak HLLabelButtonNode *victoryButtonWeak = victoryButton;
     __weak SKSpriteNode *dismissNodeWeak = dismissNode;
     __weak HLScrollNode *goalsOverlayWeak = goalsOverlay;

     if (victoryButton) {
       [victoryButton hlSetGestureTarget:[[HLTapGestureTarget alloc] initWithHandleGestureBlock:^(UIGestureRecognizer *gestureRecognizer){
         if (self->_tutorialState.tutorialActive) {
           [self FL_tutorialRecognizedAction:FLTutorialActionGoalsDismissed withArguments:nil];
         }
         [self unregisterDescendant:victoryButtonWeak];
         [self unregisterDescendant:dismissNodeWeak];
         [self unregisterDescendant:goalsOverlayWeak];
         self->_goalsState.clear();
         // noob: Retain a strong reference to block owner when dismissing the modal node; nobody else
         // is retaining the victoryButton, but we'd like to finish running this block before getting
         // deallocated.  The weak reference is copied with the block at copy time; now this strong
         // reference (though theoretically possibly nil) will exist until we're done the block.  It's
         // not actually clear how necessary this is, because I don't usually see problems unless this
         // block starts deleting a whole bunch of stuff (like if the didTapNext delegate method deletes
         // the scene right away, as it is prone to do if it is not careful).
         __unused HLLabelButtonNode *victoryButtonStrongAgain = victoryButtonWeak;
         [self dismissModalNodeAnimation:HLScenePresentationAnimationNone];
         id<FLTrackSceneDelegate> delegate = self.delegate;
         if (delegate) {
           // noob: So this is dangerous.  The delegate is probably going to delete this scene.
           // We've got strong references to the scene copied with the block, so let's make sure
           // the block is gone before we try to deallocate the scene.  Okay so wait that's a problem
           // with all existing blocks that reference self, right?  Like, they should all have __weak
           // references?  Unless SKNode explicitly releases children during its deallocation.
           // Sooooo . . . that's something to test.  For now, there aren't crashes, and if there's
           // a retain cycle I haven't noticed it yet.
           [delegate performSelector:@selector(trackSceneDidTapNextLevelButton:) withObject:self];
         }
       }]];
       [self registerDescendant:victoryButton withOptions:[NSSet setWithObject:HLSceneChildGestureTarget]];
     }

  ...etc...
*/
