//
//  HLScene.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/21/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLGestureTarget.h"

/**
 A mode specifying how hit-testing should work in a gesture recognition system.

 @bug Seemingly obvious, but currently unimplemented, would be a mode where intersecting
      nodes are collected by `[SKNode nodesAtPoint]` and then traversed in order of
      `zPosition` (highest to lowest).  `HLSceneGestureTargetHitTestModeZPosition`,
      presumably.  But parent-traversal is already coded, and works in simple cases, so
      I'm delaying implementation until I have a use-case for `zPosition`-only.

 @bug Okay, I had one use case: I wanted to flash the entire scene white, and so naively I
      overlaid a white sprite node on the scene and animated its alpha.  Gesture handling
      started with the highest z-position object, which was the white node, because it was
      over everything.  In particular, it covered over multiple gesture targets which I
      still wanted to work.  (If there were just one target enabled, then I could make the
      white node the child of that target, and gestures would fall through according to
      the "ThenParent" of the hit test mode.  But that doesn't work for multiple covered
      targets.)  I preferred to work around the problem (by flashing white in a different
      way), but it still makes a good use case.  The opposite case is this: It's nice to
      be able to disable interaction in the scene by covering everything with a matte
      which has a top-level parent.  However, that function is not impossible when doing
      HLSceneGestureTargetHitTestModeZPosition (for example, the matte could be itself a
      gesture target which explicitly does nothing).  One more idea along these lines:
      Rather than having a scene-wide mode, could each node in the tree (optionally) have
      its own mode?  Like, the scene mode is to find the first target, either "deepest" or
      "z-position", but then that first target is queried to see how to traverse the node
      tree, whether by node parent or z-position?
*/
typedef NS_ENUM(NSInteger, HLSceneGestureTargetHitTestMode) {
  /**
   Uses `[SKNode nodeAtPoint]` to find the deepest intersecting node, and then traverses
   up the node tree looking for handlers.  Presumably this mode works best with `SKScene`s
   where `ignoresSiblingOrder` is `NO` (the default), so that this hit-test finds things
   in render order.
  */
  HLSceneGestureTargetHitTestModeDeepestThenParent,
  /**
   Uses `[SKNode nodesAtPoint]` to find the intersecting node with the highest
   `zPosition`, and then traverses up the node tree looking for handlers.  Presumably this
   mode works best with `SKScene`s where `ignoresSiblingOrder` is `YES`, so that this
   hit-test finds the top target in render order.
  */
  HLSceneGestureTargetHitTestModeZPositionThenParent,
  //HLSceneGestureTargetHitTestModeZPosition,
};

/**
 A style of animation for presentation or dismissal of modal nodes.
*/
typedef NS_ENUM(NSInteger, HLScenePresentationAnimation) {
  /**
   No animation during presentation or dismissal of modal nodes.
  */
  HLScenePresentationAnimationNone,
  /**
   A short fade animation during presentation or dismissal of modal nodes.
  */
  HLScenePresentationAnimationFade,
};

/**
 Optional behaviors for descendant nodes in the scene's node tree.

 Intended for extension by subclasses.  Identifiers for new options should be prefixed
 with class name to namespace them; values should be strings containing the identifier
 name.
*/
/**
 Option for `registerDescendant:withOptions:`: Do not encode this node (or any of its
 children) during <NSCoding> operations.
*/
FOUNDATION_EXPORT NSString * const HLSceneChildNoCoding;
/**
 Option for `registerDescendant:withOptions:`: Set this node's size property with the size
 of the scene when the scene size changes.
*/
FOUNDATION_EXPORT NSString * const HLSceneChildResizeWithScene;

/**
 `HLScene` contains functionality useful to many scenes, including but not limited to:

   - loading scene assets in a background thread

   - registration of nodes for common scene-related behaviors (for example, resizing when
     the scene resizes, and not encoding when the scene encodes)

   - a shared gesture recognition system and an `HLGestureTarget`-aware gesture delegate
     implementation

   - modal presentation of a node above the scene

 ## Shared Gesture Recognition System

 `HLScene` includes a gesture recognition system that can forward `UIGestureRecognizer`
 gestures to `HLGestureTarget` nodes.  The system implementation works by magic and does
 exactly what you want it to without configuration.  If, however, you do not want to
 partake in the mysteries, do not call `needSharedGestureRecognizers*`.

 ### Subclassing Notes for the Shared Gesture Recognition System

 - The `HLScene` calls the `needSharedGestureRecognizers:` method to create gesture
   recognizers for any gesture recognizers needed by `HLGestureTarget` nodes registered
   with `registerDescendant:withOptions:`.

 - Subclasses shall call the `needSharedGestureRecognizers:` to create any other needed
   gesture recognizers.  The method is safe to call multiple times, and will only create
   gesture recognizers if an equivalent one (according to
   `HLGestureTarget_areEquivalentGestureRecognizers()`) is not already created.

 - The `HLScene` implementation of `[SKScene didMoveToView:]` adds any created gesture
   recognizers to the view.  The implementation of `[SKScene willMoveFromView:]` removes
   them.  (Gesture recognizers created in between will add themselves to the scene's view
   automatically.)

 - The entry point for the shared gesture recognition system in action is
   `gestureRecognizer:shouldReceiveTouch:`.  Subclasses overriding that method should call
   `super` in order to allow the shared gesture recognition system to find targets and
   forward gestures.
*/
#if TARGET_OS_IPHONE
@interface HLScene : SKScene <NSCoding, UIGestureRecognizerDelegate>
#else
@interface HLScene : SKScene <NSCoding, NSGestureRecognizerDelegate>
#endif

/// @name Loading Scene Assets

/**
 Calls `loadSceneAssets` in a background thread, and, when finished, calls the
 `completion` on the main thread.
*/
+ (void)loadSceneAssetsWithCompletion:(void(^)(void))completion;

/**
 Overridden by the `HLScene` subclass to load all scene assets.
*/
+ (void)loadSceneAssets;

/**
 Returns `YES` if `loadSceneAssets` has been called.
*/
+ (BOOL)sceneAssetsLoaded;

/**
 Logs a non-critical error if `loadSceneAssets` has not been called.
*/
+ (void)assertSceneAssetsLoaded;

/// @name Registering Nodes With Custom Behavior

/**
 Convenience method which calls `registerDescendant:withOptions:` when adding a child.
*/
- (void)addChild:(SKNode *)node withOptions:(NSSet *)options;

/**
 Registers a node (a descendant in the scene's node tree) for various automatic behavior
 in the scene.

 See documentation of `HLSceneChild*` values.

 In general it is not strictly required that the node be currently part of the scene's
 node tree, but certain options might assume it.

 Custom behavior attempts to be extremely low-overhead for non-registered nodes, so that
 scenes can subclass `HLScene` and only subscribe to the desired behavior without other
 impact.  Some memory overhead is to be expected, both for the class and for registered
 nodes; nodes can be unregistered by `unregisterDescendant:`.

 Failure to unregister nodes often has little functional impact, but it will retain
 references unnecessarily.

 @bug One problem with the current design, for the record: Each node (usually) gets
      retained in a collection for its feature.  If many nodes are registered, then the
      memory use will be significant.  That said, the options do not lend themselves to
      widespread use on lots and lots of nodes in the scene.

 @bug An alternate design would be to put requests for scene behavior in the nodes
      themselves (perhaps by having them conform to protocols, or perhaps by having them
      subclass a `HLNode` class which can track desired options).  Then, children in the
      scene don't need to be added specially; they can be discovered during normal adding
      with addChild:, or else discovered lazily (by scanning the node tree) when needed.
      The main drawback seems to be an invisible performance impact (no matter how small)
      for the `HLScene` subclass.  With explicit registration, the subclasser can be
      relatively confident that nothing is going on that wasn't requested.
*/
- (void)registerDescendant:(SKNode *)node withOptions:(NSSet *)options;

/**
 Unregisters a node.

 Nodes are registered by `registerDescendant:withOptions:`.  See documentation there for
 comments on unregistration.
*/
- (void)unregisterDescendant:(SKNode *)node;

/// @name Configuring the Shared Gesture Recognizer System

/**
 The mode used for hit-testing in the `HLScene` implementation of
 `[UIGestureRecognizerDelegate gestureRecognizer:shouldReceiveTouch:]`.

 `HLScene` which implements `gestureRecognizer:shouldReceiveTouch`: to look for
 `HLGestureTarget` nodes which intersect the touch and see if any of them want to handle
 the gesture.  The `HLSceneGestureTargetHitTestMode` determines the way that the method
 finds targets: Should it start with the node deepest in the tree, or with the highest
 `zPosition`?  If not stopping with the first node hit, should it then look for more
 targets by traversing parents in the node tree, or again by `zPosition`?

 See `HLSceneGestureTargetHitTestMode` for the options.

 Default value is `HLSceneGestureTargetHitTestModeDeepestThenParent`, which corresponds to
 the default false value for `SKView ignoresSiblingOrder`.
*/
@property (nonatomic, assign) HLSceneGestureTargetHitTestMode gestureTargetHitTestMode;

/**
 Instructs the scene that certain gesture recognizers, needed by a particular node, should
 be added to the shared gesture recognizer system.

 Before adding, each passed gesture recognizer is checked to see if it is equivalent to a
 gesture recognizer already added to the shared gesture recognizer system.  Equivalent
 gesture recognizer are defined by `HLGestureTarget_areEquivalentGestureRecognizers()`.

 For gesture recognizers not already added, this method:

 - adds the gesture recognizer to the shared list;
 - adds it to the scene's view (if the view exists);
 - sets the `HLScene` as delegate;
 - and removes any existing target/action pairs.

 This method does nothing if the gesture recognizer is equivalent to one already added.

 Recognizers added before the scene's view exists will be added to the view by `[HLScene
 didMoveToView]`.
*/
- (void)needSharedGestureRecognizersForNode:(SKNode *)node;

/**
 Instructs the scene that certain specific gesture recognizers should be added to the
 shared gesture recognizer system.

 See `needSharedGestureRecognizersForNode:` for details.  Needing gesture recognizers for
 a node is the common use pattern; this method is used instead when building improvised
 gesture recognition directly into a scene (without a gesture target).
*/
- (void)needSharedGestureRecognizers:(NSArray *)gestureRecognizer;

/**
 Removes all shared gesture recognizers from the scene.

 This effectively disables the gesture target system of `HLScene`, as if
 `needSharedGestureRecognizers*` had never been called.
*/
- (void)removeAllSharedGestureRecognizers;

/// @name Presenting a Modal Node

/**
 Presents a node modally above the current scene, disabling other interaction.

 By convention, the modal layer is not persisted during scene encoding.

 The goal is to present the modal node "above" the current scene, which may or may not
 require careful handling of `zPosition`, depending on `[SKView ignoresSiblingOrder]`.
 It's left to the caller to provide an appropriate `zPosition` range that can be used by
 this scene to display the presented node and other related decorations and animations.
 The presented node will have its `zPosition` set to a value in the provided range, but
 exactly what value is implementation-specific.  The range may be passed empty; that is,
 min and max may the the same.  If the `zPositionMin` and `zPositionMax` parameters are
 not needed, `presentModalNode:animation:` may be called instead.

 @param node The node to present modally.  The scene will not automatically dismiss the
             presented node.

 @param animation Optional animation for the presentation.  See
                  `HLScenePresentationAnimation`.

 @param zPositionMin A lower bound (inclusive) for a range of `zPosition`s to be used by
                     the presented node and other related decorations and animations.  See
                     note in discussion.

 @param zPositionMax An upper bound (inclusive) for a range of `zPosition`s to be used by
                     the presented node and other related decorations and animations.  See
                     note in discussion.
*/
- (void)presentModalNode:(SKNode *)node
               animation:(HLScenePresentationAnimation)animation
            zPositionMin:(CGFloat)zPositionMin
            zPositionMax:(CGFloat)zPositionMax;

/**
 Convenience method for calling `presentModalNode:animated:zPositionMin:zPositionMax:`
 with `0.0` passed to the last two parameters.

 This is a more readable (more sensible looking) version when the scene does not need
 `zPositions` passed in; usually if the `HLScene` is subclassed, this will be the
 preferred invocation (since the subclass will override the main present modal node method
 to ignore the passed-in `zPositions`).
*/
-(void)presentModalNode:(SKNode *)node
              animation:(HLScenePresentationAnimation)animation;

/**
 Dismisses the node currently presented (if any).
*/
- (void)dismissModalNodeAnimation:(HLScenePresentationAnimation)animation;

/**
 Returns the node currently presented, or `nil` for none.
*/
- (SKNode *)modalNodePresented;

@end
