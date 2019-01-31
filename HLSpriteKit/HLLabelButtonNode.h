//
//  HLLabelButtonNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/2/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLComponentNode.h"
#import "SKLabelNode+HLLabelNodeAdditions.h"

/**
 HLLabelButtonNode displays a label over a textured or colored background.  It
 intentionally mimics an `SKLabelNode` on top of a `SKSpriteNode`, but has extra sizing
 and alignment options.

 ## Common User Interaction Configurations

 You might think this node, as a so-called "button", would have more options for handling
 user interaction (whether as a gesture target, a `UIResponder`, or an `NSResponder`).
 However, it does not, because the handling code would be so basic that it would seem
 ridiculous.  For instance, should every button in the scene keep a pointer to a delegate,
 and invoke delegate callbacks for interaction?  Seems unnecessary.  Instead, the button
 is mostly used in composing more-complicated components.  For instance, `HLMenuNode`
 keeps a collection of `HLLabelButtonNode` objects, and handles the interaction for all of
 them.

 That said, under the gesture target system, any node can be configured as a gesture
 target.  `HLLabelButtonNode` just doesn't have a self-as-target implementation as, for
 instance, `HLGridNode` does.

 As a gesture target:

 * Leave the gesture target unset for no gesture handling.

 * Allocate a `HLTapGestureTarget`, initialize it with a block for execution on tap, and
   set it as gesture target (using `[SKNode+HLGestureTarget hlSetGestureTarget]`).

 * For double-tap, long press, or other gestures, set a custom `HLGestureTarget`
   instead.
*/

@interface HLLabelButtonNode : HLComponentNode <NSCopying, NSCoding>

/// @name Creating a Label Button Node

/**
 Initializes a new label button node with a solid color background.
*/
- (instancetype)initWithColor:(SKColor *)color size:(CGSize)size;

/**
 Initializes a new label button node with a texture.
*/
- (instancetype)initWithTexture:(SKTexture *)texture;

/**
 Initializes a new label button node with a texture created from the named image.

 See `[SKSpriteNode initWithImageNamed:]` for details; texture atlases and the application
 bundle are both searched for the image.
*/
- (instancetype)initWithImageNamed:(NSString *)name;

/// @name Getting and Setting Content

/**
 The text of the label button node.

 **Layout of the components of the label button will not be performed if the text is
 unset.** During initial configuration, then, the caller may set the text after setting
 all other layout-affecting properties, and layout will only be performed once.
*/
@property (nonatomic, copy) NSString *text;

/// @name Configuring Geometry and Alignment

/**
 Sets or returns the overall size of the button.

 When setting, size dimensions may be ignored (and overwritten) depending on the values of
 `automaticWidth` and `automaticHeight`.
*/
@property (nonatomic, assign) CGSize size;

/**
 Specifies the anchor point of the button.

 Default value `(0.5, 0.5)`.
*/
@property (nonatomic, assign) CGPoint anchorPoint;

/**
 Specifies if the button should automatically set its width based on the label width.

 Label width is determined by various properties including its text, font, and padding.

 Default value is `NO`.
*/
@property (nonatomic, assign) BOOL automaticWidth;

/**
 Specifies if the button should automatically set its height based on the label height.

 Label height is determined by various properties including its text, font, padding, and
 height mode.  The height mode in particular is worth considering, because it can change
 the normal meaning of SpriteKit label height (based on the current text) to other
 useful options (for example, the inherent height of the font).  See `heightMode` for
 more information.

 Default value is `NO`.
*/
@property (nonatomic, assign) BOOL automaticHeight;

/**
 Specifies how to calculate the label height when considering vertical alignment
 and automatic height.

 See `automaticHeight` for additional information.

 Default value is `HLLabelHeightModeText`.

 Using the default value, the baseline of the label text will appear to jump around when
 the text changes (for most fonts).  Furthermore, the baselines of two label buttons
 side-by-side will probably be different.  An alternative to consider is
 `HLLabelHeightModeAscenderBias`, which keeps the baselines consistent and does a pretty
 good job of visually centering various text strings in most fonts.
*/
@property (nonatomic, assign) HLLabelHeightMode heightMode;

/**
 The amount of space, when using `automaticWidth`, to leave between the label and the edge
 of the button.

 Default value is `0.0`.
*/
@property (nonatomic, assign) CGFloat labelPadX;

/**
 The amount of space, when using `automaticHeight`, to leave between the label and the
 edge of the button.

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

 The default value is determined by `[SKLabelNode fontColor]` (currently white).
*/
@property (nonatomic, strong) SKColor *fontColor;

/**
 An alpha for the background node (not the label).

 Both background and label are affeted by the label button node's `alpha` value.
*/
@property (nonatomic, assign) CGFloat backgroundAlpha;

/**
 The color used by the background node, or the color blended into the background node's
 texture by a non-zero `colorBlendFactor`.
*/
@property (nonatomic, strong) SKColor *color;

/**
 The amount to blend the `color` into the background node's texture, if any.
*/
@property (nonatomic, assign) CGFloat colorBlendFactor;

/**
 A rectangle which defines how the texture (if any) should be stretched to fit the label
 button node's size.

 See `[SKSpriteNode centerRect]`.
*/
@property (nonatomic, assign) CGRect centerRect;

@end
