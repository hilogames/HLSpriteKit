//
//  HLIconNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 8/6/18.
//  Copyright (c) 2018 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "SKLabelNode+HLLabelNodeAdditions.h"

/**
 HLIconNode is a texture with an optional text label centered below.

 The label of an icon is considered optional or unimportant in a few ways:

   - Geometric properties like `size` and `anchorPoint` refer only to the texture portion
     of the icon node, and ignore the label.

   - Icon nodes (like iOS app icons) do not generally intend to respond to user
     interaction targeting their labels.  (That said, the generic `HLGestureTarget`
     implementation uses `SKNode calculateAccumulatedFrame` for hit-testing, which might
     very well include the icon label.  The same is true of `SKNode containsPoint:`.)

 ## Common User Interaction Configurations

 You might think this node would have more options for handling user interaction (whether
 as a gesture target, a `UIResponder`, or an `NSResponder`).  However, it does not,
 because the handling code would be so basic that it would seem ridiculous.  For instance,
 should every icon in the scene keep a pointer to a delegate, and invoke delegate
 callbacks for interaction?  Seems unnecessary.  Instead, the icon is mostly used in
 composing more-complicated components.

 That said, under the gesture target system, any node can be configured as a gesture
 target.  `HLIconNode` just doesn't have a self-as-target implementation as, for
 instance, `HLGridNode` does.

 As a gesture target:

 * Leave the gesture target unset for no gesture handling.

 * Allocate a `HLTapGestureTarget`, initialize it with a block for execution on tap, and
   set it as gesture target (using `[SKNode+HLGestureTarget hlSetGestureTarget]`).

 * For double-tap, long press, or other gestures, set a custom `HLGestureTarget`
   instead.
*/

@interface HLIconNode : SKNode <NSCopying, NSCoding>

/// @name Creating an Icon Node

/**
 Initializes a new icon node with a texture.
*/
- (instancetype)initWithTexture:(SKTexture *)texture;

/**
 Initializes a new icon node with a texture created from the named image.

 See `[SKSpriteNode initWithImageNamed:]` for details; texture atlases and the application
 bundle are both searched for the image.
*/
- (instancetype)initWithImageNamed:(NSString *)name;

/// @name Getting and Setting Content

/**
 The texture of the icon node.
*/
@property (nonatomic, strong) SKTexture *texture;

/**
 The text for the label of the icon node.

 **Most layout of the components of the icon node is not necessary and will not be
 performed if the text is unset.**  During initial configuration, then, the caller may set
 the text after setting all other layout-affecting properties, and layout will only be
 performed once.
*/
@property (nonatomic, copy) NSString *text;

/// @name Configuring Geometry and Alignment

/**
 The size of the texture portion of the icon node.
*/
@property (nonatomic, assign) CGSize size;

/**
 The anchor point for the texture portion of the icon node.

 Default value `(0.5, 0.5)`.
*/
@property (nonatomic, assign) CGPoint anchorPoint;

/**
 Specifies how to calculate the label height when positioning the label below the texture,
 and when vertically aligning the text of the label.

 Default value is `HLLabelHeightModeText`.

 Since the label is aligned by its top, the main choice is between text-aligned and
 font-aligned.  When using `HLLabelHeightModeText`:

   - The space between the bottom of the texture and the top of the label will stay
     the same regardless of text (for instance, whether it has ascenders or not);

   - but the distance from the bottom of the texture to the baseline will change based
     on the text.

 When using `HLLabelHeightModeFont*`:

   - The distance from the bottom of the texture to the baseline will stay the same
     regardless of text (for instance, whether it has ascenders or not);

   - but the space between the bottom of the texture and the top of the label will
     change based on the text.
*/
@property (nonatomic, assign) HLLabelHeightMode heightMode;

/**
 The amount of space to leave between the label and the bottom edge of the texture.

 Default value is `0.0`.
*/
@property (nonatomic, assign) CGFloat labelPadY;

/**
 The font used by the label.
*/
@property (nonatomic, copy) NSString *fontName;

/**
 The font size used by the label.

 The default value is determined by `[SKLabelNode fontSize]` (currently `32` points).
*/
@property (nonatomic, assign) CGFloat fontSize;

/// @name Configuring Appearance

/**
 The font color used by the label.

 The defualt value is determined by `[SKLabelNode fontColor]` (currently white).
*/
@property (nonatomic, strong) SKColor *fontColor;

/**
 The color applied to the icon node.
*/
@property (nonatomic, assign) SKColor *color;

/**
 A value that describes how the `color` is blended with the icon node's texture.
*/
@property (nonatomic, assign) CGFloat colorBlendFactor;

@end
