//
//  HLGestureTarget.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 2/4/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

/**
 * A generic target for UIGestureRecognizers.
 *
 * Use case: A single delegate for a bunch of gesture recognizers creates and maintains the recognizers,
 * but wants to forward the gesture to different targets based on where the gesture starts.  An example
 * might be an SKScene, which has only a single view (and hence only a single set of gesture recognizers),
 * but perhaps many different SKNode components within the scene, like a world, a character, or a toolbar.
 * Upon receiving the first touch of a particular gesture, the SKScene finds likely HLGestureTarget
 * components and offers them the chance to become targets of that gesture.  See HLScene for a
 * simple implementation.
 */

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

@protocol HLGestureTarget <NSObject>

/**
 * Adds itself (as target of an action) to the passed gesture recognizer if it is interested in the
 * particular gesture and first-touch location.  Returns true if added; this helps the caller determine
 * if any of its targets care about the gesture.  The target adds itself with a call like this:
 *
 *    [gestureRecognizer addTarget:self action:@selector(handleTap:)];
 *
 * note: The implementation of this method should assume that it is not already added as a target
 * to the gesture recognizer.  (It is typical for the caller to clear all targets from the gesture
 * recognizer before then offering it to be claimed by one or more of its possible targets for
 * the given first touch.)
 *
 * Returns an additional boolean indicating whether the touch location is "inside" the target,
 * whether or not the target added itself to the gesture recognizer.  This value is important so
 * that the caller can decide whether or not to offer the gesture and touch to other targets.  A
 * common example is a button target given a pan starting inside the button: The button does not
 * care about pans, and so does not add itself as a target to the gesture, but it returns isInside
 * YES, so the caller knows that the pan should probably not fall through to other targets.  (This
 * could be separated out as a separate method in HLGestureTarget, but the logic is often very
 * redundant with the decision to add self as target.)  (Also, as an motivating example: If all
 * targets were SKNodes and the caller could use containsPoint to determine whether a gesture
 * first touch was "inside" a particular target, then the target wouldn't have to weigh in.  But
 * clearly a hit test inside a bounding box is not always sufficient; it depends on the target.)
 *
 * To explain the logic, here is a sketch of a typical caller implementation.  The caller is a
 * UIGestureRecognizerDelegate of a number of standard gesture recognizers.  It has a number of
 * possible targets for the gestures, some of which are controlled completely by the caller, and
 * some of which are encapsulated into opaque components.  The motivating example is reusable
 * subclasses of SKNode, which can't own their own gesture recognizers, since they aren't UIViews.
 * On first touch of a gesture recognizer (gestureRecognizer:shouldRecieveTouch:), the caller
 * might use bounding box (e.g. SKNode's containsPoint) or other hit testing (e.g. SKNode's
 * nodeAtPoint) to find possibly-relevant targets, and then query them in order of visible layer
 * height (e.g. SKNode's zPosition): each target is asked to add itself to the gesture if it's
 * interested.  A caller might decide to only offer the gesture to the first target that claims
 * the gesture's first touch is "inside"; or, it might decide to offer the gesture to all targets
 * at a location regardless of layer height and opacity.
 */
- (BOOL)addToGesture:(UIGestureRecognizer *)gestureRecognizer firstTouch:(UITouch *)touch isInside:(BOOL *)isInside;

// Commented out: Another idea, for callers with lots of targets: A version of addToGesture to be
// implemented by SKNode descendents who care about sceneLocation not touch.  This could avoid
// every target doing the same coordinates conversion over and over.
//- (BOOL)addToGesture:(UIGestureRecognizer *)gestureRecognizer firstTouchSceneLocation:(CGPoint)sceneLocation isInside:(BOOL *)isInside;

/**
 * Returns a boolean indicating interest in particular kinds of gesture recognizers.
 * These are used by the caller to initialize and configure itself.
 *
 * note: Some callers might also be able to use these to avoid unnecessary calls to
 * addToGesture (which is assumed to be more costly), but typically a target still
 * must evaluate "is inside" even if it isn't interested in a certain kind of
 * gesture.
 */
- (BOOL)addsToTapGestureRecognizer;
- (BOOL)addsToDoubleTapGestureRecognizer;
- (BOOL)addsToLongPressGestureRecognizer;
- (BOOL)addsToPanGestureRecognizer;
- (BOOL)addsToPinchGestureRecognizer;

@end

/**
 * An SKSpriteNode which implements HLGestureTarget using an owner-provided blocks.
 *
 * Okay, so it's a bit convoluted.  But this is nice for situations when a simple
 * node needs to handle a simple gesture and subclassing seems like overkill.
 * Call it experimental.
 */
@interface HLGestureTargetSpriteNode : SKSpriteNode <HLGestureTarget>

@property (nonatomic, assign) BOOL addsToTapGestureRecognizer;
@property (nonatomic, assign) BOOL addsToDoubleTapGestureRecognizer;
@property (nonatomic, assign) BOOL addsToLongPressGestureRecognizer;
@property (nonatomic, assign) BOOL addsToPanGestureRecognizer;
@property (nonatomic, assign) BOOL addsToPinchGestureRecognizer;
@property (nonatomic, copy) void (^handleGestureBlock)(UIGestureRecognizer *);

- (BOOL)addToGesture:(UIGestureRecognizer *)gestureRecognizer firstTouch:(UITouch *)touch isInside:(BOOL *)isInside;
- (BOOL)addsToTapGestureRecognizer;
- (BOOL)addsToDoubleTapGestureRecognizer;
- (BOOL)addsToLongPressGestureRecognizer;
- (BOOL)addsToPanGestureRecognizer;
- (BOOL)addsToPinchGestureRecognizer;

@end

