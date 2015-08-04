//
//  HLLabelButtonNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/2/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLComponentNode.h"
#import "HLGestureTarget.h"
#import "SKLabelNode+HLLabelNodeAdditions.h"

/**
 HLLabelButtonNode displays a label over a textured or colored background.  It
 intentionally mimics an `SKLabelNode` on top of a `SKSpriteNode`, but has extra sizing
 and alignment options.

 ## Common Gesture Handling Configurations

 * Leave the gesture target unset for no gesture handling.

 * Allocate a `HLTapGestureTarget`, initialize it with a block for execution on tap, and
   set it as gesture target (via `[SKNode+HLGestureTarget hlSetGestureTarget]`).

 * For double-tap, long press, or other gestures, set a custom `HLGestureTarget`
   instead.

 @bug There is no current self-as-target option for `HLLabelButtonNode` (as there is in,
      for example, `HLGridNode` and `HLMenuNode`).  It would be pretty easy to make one: A
      callback block for taps, probably.  But of course that functionality is pretty
      easily specified by instantiating a tap delegate.  Other components have
      more-complex interactions (e.g. for `HLGridNode`, not just that a tap occurred, but
      *which* square it occurred on) (and e.g. for `HLMenuNode`, both `shouldTap` and
      `didTap` delegate methods).  The button might be too generic and simple to have a
      natural self-as-target built-in behavior.
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
 
 Default value `(0.5,0.5)`.
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
 vertical alignment mode.

 Default value is `NO`.
 */
@property (nonatomic, assign) BOOL automaticHeight;

/**
 Specifies how to align the label within the button frame.

 See documentation for `HLLabelNodeVerticalAlignmentMode`.  This alignment mode also
 determines the calculated height used for the button when `automaticHeight` is true.

 Default value is `HLLabelNodeAlignText`.
 */
@property (nonatomic, assign) HLLabelNodeVerticalAlignmentMode verticalAlignmentMode;

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
 
 The defualt value is determined by `[SKLabelNode fontColor]` (currently white).
 */
@property (nonatomic, strong) SKColor *fontColor;

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

/**
 The corner radius of the button. 
 
 Default value is `0.0`.
 
 Note: property will only work for label buttons that don’t have a texture.
 */
@property (nonatomic, assign) CGFloat cornerRadius;

/**
 The boarder width of the button.
 
 Default value is `0.0`.
 Default color is [SKColor blackColor]
 */
@property (nonatomic, assign) CGFloat borderWidth;

/**
 The color of the border for the button.
 
 Default value is [SKColor blackColor]
 */
@property (nonatomic, strong) SKColor *borderColor;

@end
