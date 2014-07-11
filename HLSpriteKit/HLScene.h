//
//  HLScene.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/21/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>

/**
 * HLScene contains functionality useful to many scenes, including but not limited to:
 *
 *   - loading scene assets in a background thread
 *
 *   - a shared gesture recognition system
 *
 *   - modal presentation of a node above the scene
 *
 *   - registration of nodes for common scene-related behaviors (e.g. resizing when the
 *     scene resizes; not encoding when the scene encodes; etc)
 *
 * note: Composition would be better than inheritance.  Can functionality be grouped into
 * modules or functions?
 */

/**
 * Optional behaviors for descendant nodes in the scene's node tree.
 *
 *   HLSceneChildNoCoding: Do not encode this node (or any of its children) during
 *                         <NSCoding> operations.
 *
 *   HLSceneChildResizeWithScene: Set this node's size property with the size of the scene
 *                                when the scene size changes.
 *
 *   HLSceneChildGestureTarget: Considers this <HLGestureTarget> child node when
 *                              processing gestures with the default HLScene gesture
 *                              recognition system; see HLGestureTarget.
 *
 * Intended for extension by subclasses.  Constant identifiers should be prefixed with
 * class name to namespace them; values should strings containing the identifier name.
 */
FOUNDATION_EXPORT NSString * const HLSceneChildNoCoding;
FOUNDATION_EXPORT NSString * const HLSceneChildResizeWithScene;
FOUNDATION_EXPORT NSString * const HLSceneChildGestureTarget;

@interface HLScene : SKScene <NSCoding, UIGestureRecognizerDelegate>
{
@protected
  /**
   * Shared gesture recognizers for common gesture types.  See notes on the shared gesture
   * recognizer system, below.
   */
  UITapGestureRecognizer *_tapRecognizer;
  UITapGestureRecognizer *_doubleTapRecognizer;
  UILongPressGestureRecognizer *_longPressRecognizer;
  UIPanGestureRecognizer *_panRecognizer;
  UIPinchGestureRecognizer *_pinchRecognizer;
}

// Functionality for loading scene assets.

+ (void)loadSceneAssetsWithCompletion:(void(^)(void))completion;

+ (void)loadSceneAssets;

+ (BOOL)sceneAssetsLoaded;

+ (void)assertSceneAssetsLoaded;

// Functionality for registering nodes with custom behavior in the scene.

/**
 * Convenience method which calls registerDescendant:withOptions: when adding a child.
 */
- (void)addChild:(SKNode *)node withOptions:(NSSet *)options;

/**
 * Registers a node (a descendant in the scene's node tree) for various automatic behavior
 * in the scene; see documentation of HLSceneChild* values, above.
 *
 * In general it is not strictly required that the node be currently part of the scene's
 * node tree, but certain options might assume it.
 *
 * Custom behavior attempts to be extremely low-overhead for non-registered nodes, so that
 * scenes can subclass HLScene and only subscribe to the desired behavior without other
 * impact.  Some memory overhead is to be expected, both for the class and for registered
 * nodes; nodes can be unregistered by unregisterDescendant:.
 *
 * Failure to unregister nodes often has little functional impact, but it will retain
 * references unnecessarily.
 *
 * note: One problem with the current design, for the record: Each node gets registered as
 * a pointer in an NSSet for its feature.  If many nodes are registered, then the memory
 * use will be significant.  That said, the options do not lend themselves to widespread
 * use on lots and lots of nodes in the scene.  One option to keep an eye on is gesture
 * target registration: Probably HLScene's gesture recognition system is not suited to use
 * for lots and lots of targets.
 *
 * note: An alternate design would be to put requests for scene behavior in the nodes
 * themselves (perhaps by having them conform to protocols, or perhaps by having them
 * subclass a HLNode class which can track desired options).  Then, children in the scene
 * don't need to be added specially; they can be discovered during normal adding with
 * addChild:, or else discovered lazily (by scanning the node tree) when needed.  The main
 * drawback seems to be an invisible performance impact (no matter how small) for the HLScene
 * subclass.  With explicit registration, the subclasser can be relatively confident that
 * nothing is going on that wasn't requested.  Also with explicit registration, the caller
 * is able to override node information, for example not registering a child for gesture
 * recognition even though it conforms to HLGestureTarget.
 *
 * note: Okay, one more note: I waffle a bit on gesture targets.  They are easily discovered
 * implicitly (by their conformance to HLGestureTarget); the use case for adding an
 * HLGestureTarget to a scene but not wanting it to receive gestures is small (and could
 * be addressed by registering a node to *not* be a target if needed); and it's somewhat
 * surprising when you add some kind of interactive node to a scene and it doesn't
 * interact.  But, on the other hand: It's really nice having the HLScene manage the
 * shared gesture recognizer objects during registration (by asking the target what
 * recognizers it needs).  So, waffle.
 */
- (void)registerDescendant:(SKNode *)node withOptions:(NSSet *)options;

/**
 * Unregisters a node registered by registerDescendant:withOptions:.  See docoumentation
 * in registerDescendant:withOptions: for comments on unregistration.
 */
- (void)unregisterDescendant:(SKNode *)node;

// Functionality for shared gesture recognition system.

/**
 * Current interface is protected and unsafe.  It will evolve into something safer,
 * and this documentation will certainly be updated.  Certainly.
 *
 * HLScene implements a gesture recognition system that can forward gestures to
 * HLGestureTarget nodes registered the appropriate option (in registerDescendant:).  The
 * system implementation works by magic and does exactly what you want it to without
 * configuration.  If, however, you do not want to partake in the mysteries, do not
 * register any nodes with the gesture target option, and feel free not to call super on
 * any of the UIGestureRecognizerDelegate methods (though they will try not to do anything
 * surprising if called).
 *
 * Notes for subclasses:
 *
 *   - The gesture recognizers are stored in shared protected variables for easy and quick
 *     access.  The rationale for shared: We want as few gesture recognizers on the
 *     scene as possible, and we assume they should almost always be configured the same
 *     way (e.g. a long press should take the same amount of time in all parts of the
 *     interface).  But if direct ivar access proves messy, we can provide accessors
 *     instead.
 *
 *   - The HLScene calls needShared*GestureRecognizer methods to create gesture
 *     recognizers for any gesture recognizers needed by HLGestureTarget nodes registered
 *     with registerDescendant.
 *
 *   - The HLScene implementation of didMoveToView adds any created gesture recognizers
 *     to the view.  The implementation of willMoveFromView removes them.  (Gesture
 *     recognizers created in between will add themselves to the scene's view automatically.)
 *
 *   - Subclasses shall call the gesture recognizer need* methods to create needed gesture
 *     recognizers.  The need* methods are safe to call multiple times, and will only
 *     create the gesture recognizer if it is not already created.
 *
 *   - Subclasses may override gesture recognizer need methods to configure the gesture
 *     recognizers as desired.  (Alternately, subclasses may configure the gesture
 *     recognizers at the time of their choosing by accessing the ivars directly.)  If
 *     overridden, the methods should be sensitive to repeated calls, as documented, and
 *     should also add any newly created gesture recognizers to the scene's view (if it
 *     exists at creation time).
 */

/**
 * If the shared gesture recognizer does not already exist:
 *
 *   - creates a shared gesture recognizer;
 *   - adds it to the scene's view (if it exists);
 *   - sets the HLScene as delegate;
 *   - and configures the recognizer with a dummy target.
 *
 * If the recognizer already exists, does nothing.  Returns a boolean indicating whether
 * or not the recognizer was created.  (This might be useful for subclasses which want to
 * allow the default implementation to create the recognizer, but then configure it when
 * first created.)
 *
 * Note that recognizers created before the scene's view exists will be added to the view
 * by HLScene's didMoveToView.
 */
- (BOOL)needSharedTapGestureRecognizer;
- (BOOL)needSharedDoubleTapGestureRecognizer;
- (BOOL)needSharedLongPressGestureRecognizer;
- (BOOL)needSharedPanGestureRecognizer;
- (BOOL)needSharedPinchGestureRecognizer;

// Functionality for presenting a node modally above the scene.

/**
 * Presents a node modally above the current scene, disabling other interaction.
 *
 * By convention, the modal layer is not persisted during scene encoding.
 *
 * note: "Above" the current scene might or might not depend on (a particular) zPosition,
 * depending on whether the SKView ignoresSiblingOrder.  It's left to the caller to
 * provide an appropriate zPosition range that can be used by this scene to display the
 * presented node and other related decorations and animations.  The presented node will
 * have its zPosition set to a value in the provided range, but exactly what value is
 * implementation-specific.  The range may be passed empty; that is, min and max may the
 * the same.
 *
 * @param The node to present modally.  The scene will not automatically dismiss the
 *        presented node.  (As with all HLScene nodes, if the node or any of its children
 *        are HLGestureTargets registered with the scene as HLSceneChildGestureTarget then
 *        it will have gestures forwarded to it by the HLScene's gesture handling code.)
 *
 * @param A lower bound (inclusive) for a range of zPositions to be used by the presented
 *        node and other related decorations and animations.  See note above.
 *
 * @param An upper bound (inclusive) for a range of zPositions to be used by the presented
 *        node and other related decorations and animations.  See note above.
 */
- (void)presentModalNode:(SKNode *)node
            zPositionMin:(CGFloat)zPositionMin
            zPositionMax:(CGFloat)zPositionMax;

/**
 * Convenience method for calling presentModalNode:zPositionMin:zPositionMax: with 0.0f
 * passed to the second two parameters.  This is a more readable (more sensible looking)
 * version when the scene does not need zPositions passed in; usually if the HLScene is
 * subclassed, this will be the preferred invocation (since the subclass will override
 * the main present modal node method to ignore the passed-in zPositions).
 */
-(void)presentModalNode:(SKNode *)node;

/**
 * Dismisses the node currently presented by presentModalNode (if any).
 */
- (void)dismissModalNode;

/**
 * Returns true if a modal node is currently presented by presentModalNode.
 */
- (BOOL)modalNodePresented;

@end
