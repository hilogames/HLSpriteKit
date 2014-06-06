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
 * The shared gesture recognition system might need a little extra documentation, because
 * its entry point is not obvious.  HLScene implements a gesture recognition system that
 * can forward gestures to HLGestureTarget nodes registered the appropriate option (in
 * registerDescendant:withOptions:).  The system implementation works by magic and does
 * exactly what you want it to without configuration.  If, however, you do not want to
 * partake in the mysteries, do not register any nodes with the gesture target option,
 * and feel free not to call super on any of the UIGestureRecognizerDelegate methods
 * (though they will try not to do anything surprising if called).
 *
 *   TODO: We should expose a protected interface for subclasses so they can use and
 *   configure our gesture handlers for their own use in gesture handler delegate
 *   overrides.  Wait for a use case, though, to assist with implemtation.
 *
 * note: Composition would be better than inheritance.  Can functionality be grouped into
 * modules or functions?
 */

@interface HLScene : SKScene <NSCoding, UIGestureRecognizerDelegate>

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
 * Failure to unregister nodes often has little functional impact, but it might cause
 * memory leaks.  Worse, the memory leaks might be persistent, since references to
 * registered nodes are often encoded along with the HLScene.
 *
 * note: One problem with the current design, for the record: Each node gets registered as
 * a pointer in an NSSet for its feature.  If many nodes are registered, then the memory
 * use will be significant.  Currently, the options do not lend themselves to widespread
 * use in the scene.  One option to keep an eye on is gesture target registration:
 * Probably HLScene's gesture recognition system is not suited to use for lots and lots of
 * targets.
 *
 * note: An alternate design would be to put requests for scene behavior in the nodes
 * themselves (perhaps by having them conform to protocols, or perhaps by having them
 * subclass a HLNode class which can track desired options).  Then, children in the scene
 * don't need to be added specially; they can be discovered during normal adding with
 * addChild:, or else discovered lazily (by scanning the node tree) when needed.  (This
 * would have minor benefits during encoding and decoding, too, since we wouldn't have to
 * be so careful about the pointers we are encoding; see implementation notes for
 * details.)  The main drawback seems to be an invisible performance impact (no matter how
 * small) for the HLScene subclass.  With explicit registration, the subclasser can be
 * relatively confident that nothing is going on that wasn't requested.
 */
- (void)registerDescendant:(SKNode *)node withOptions:(NSSet *)options;

/**
 * Unregisters a node registered by registerDescendant:withOptions:.  See docoumentation
 * in registerDescendant:withOptions: for comments on unregistration.
 */
- (void)unregisterDescendant:(SKNode *)node;

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
 * implementation-specific.  The range may be empty; that is, min and max may be the same.
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
 * Dismisses the node currently presented by presentModalNode (if any).
 */
- (void)dismissModalNode;

@end
