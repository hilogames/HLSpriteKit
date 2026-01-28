//
//  HLComponentNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 10/6/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

/**
 `HLComponentNode` is a base class for custom `SKNode` subclasses in `HLSpriteKit`: in
 particular, for those that present themselves as a component of a user interface and
 maintain a private tree of child nodes.
*/

@interface HLComponentNode : SKNode <NSCoding, NSCopying>

/// @name Managing Layout of Child Nodes

/**
 A range of `[SKNode zPosition]` values to be used for child nodes of this component.

 By default, because of property `[SKScene ignoresSiblingOrder]`, scenes use node tree
 structure to determine rendering order of child nodes.  When `ignoresSiblingOrder` is set
 to `YES`, though, there is a potential for difficulty:

 - On one hand, a scene must remain in complete control of the `zPosition`s of its
   components, so that it can determine render order.  For instance, if two components A
   and B are siblings in the scene, the scene might choose to render B above A by
   setting `A.zPosition` to `0.0` and `B.zPosition` to `1.0`.  Component A must not then
   have a child node which has its own `zPosition` of `10.0` relative to its root node A.

 - On the other hand, the child nodes of a component are considered private by
   convention, and should only be managed by the component.

 The `zPositionScale` provides a way for the scene to limit the range or scale of
 `zPosition`s used by any children nodes of the component.  To continue the previous
 example, the scene might control rendering order like this:

     a.zPosition = 0.0f;
     a.zPositionScale = 1.0f;

     b.zPosition = 1.0f;
     b.zPositionScale = 1.0f;

 Component A will limit itself to the `zPosition`s from `[0.0, 1.0)`.  The principle
 continues to apply when components contain components, of course; a menu component
 containing button components will decide how many layers it needs, divide its own
 `zPositionScale` into smaller scales for each layer, and set each owned component with
 the smaller scale value.

 It's worth emphasizing: The component shall keep all of its child node `zPosition`s
 *less* than the largest value in the scale.  For instance, if a component has a scale of
 `3.0` and it needs three layers, it is conventional that it should calculate for its
 layers `zPosition`s of `0.0`, `1.0`, and `2.0` (and not use `3.0` or even `2.9999`).

 Default value is `1.0`.
*/
@property (nonatomic, assign) CGFloat zPositionScale;

@end

/**
 `HLComponentSingleLayerNode` is an `HLComponentNode` designed as a simple parent node
 for children `HLComponentNodes` in a single Z layer.

 In particular, when this component has its `zPositionScale` configured, it will
 configure all its component children with the same scale.

 This class is useful in certain situations where a component node is expected, and a
 component node is desirable in order to pass along `zPositionScale` to its children,
 and yet it's annoying to make a custom `HLComponentNode` subclass for such a simple
 positioning scheme.
*/
@interface HLComponentSingleLayerNode : HLComponentNode

/**
 Sets `zPosition` to zero for all node children, and sets `zPositionScale` to the full
 scale value for any children that are themselves `HLComponentNodes`.  (This is
 appropriate if all children occupy a single layer in the component.)
*/
@property (nonatomic, assign) CGFloat zPositionScale;

@end

/**
 `HLComponentLayeredNode` is an `HLComponentNode` designed as a simple parent node
 for children layered low to high in `zPosition`.

 In particular, when this component has its `zPositionScale` configured, it will
 configure its children so that the first child is at `zPosition` zero, and the others
 are incrementally layered above.  If any of the children are `HLComponentNodes`, they
 will also have their `zPositionScale` configured.

 This class is useful in certain situations where a component node is expected, and a
 component node is desirable in order to arrange children in the Z dimension, and yet
 it's annoying to make a custom `HLComponentNode` subclass for such a simple positioning
 scheme.
*/
@interface HLComponentLayeredNode : HLComponentNode

/**
 Sets `zPosition` for all node children, in order from lowest to highest through the
 scale.  Also configures `zPositionScale` to be a single slice of the scale for any
 children that are themselves `HLComponentNodes`.  (This is appropriate if all children
 are stacked from low to high in the component.)
*/
@property (nonatomic, assign) CGFloat zPositionScale;

@end
