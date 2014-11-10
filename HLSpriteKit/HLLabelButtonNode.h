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
 * HLLabelButtonNode is simply an SKLabelNode displayed over an SKSpriteNode, but with
 * extra sizing and alignment options.
 */

@interface HLLabelButtonNode : HLComponentNode <NSCopying, NSCoding>

/**
 * Common gesture handling configurations:
 *
 *   - Leave the gesture target unset for no gesture handling.
 *
 *   - Allocate a HLTapGestureTarget, initialize it with a block for execution on tap, and
 *     set it as gesture target (via SKNode+HLGestureTarget's hlSetGestureTarget).
 *
 *   - For double-tap, long press, or other gestures, set a custom HLGestureTarget
 *     instead.
 *
 * note: There is no current self-as-target option for HLLabelButtonNode (as there is in,
 * for example, HLGridNode and HLMenuNode).  It would be pretty easy to make one: A
 * callback block for taps, probably.  But of course that functionality is pretty easily
 * specified by instantiating a tap delegate.  Other components have more-complex
 * interactions (e.g. for HLGridNode, not just that a tap occurred, but *which* square it
 * occurred on) (and e.g. for HLMenuNode, both shouldTap and didTap delegate methods).
 * The button might be too generic and simple to have a natural self-as-target built-in
 * behavior.
 */

/**
 * The text of the label in the HLLabelButtonNode.  Layout of the components of the label
 * button will not be performed if the text is unset; during initialization, then, the
 * caller may set the text after setting all other layout-affecting properties, and layout
 * will only be performed once.
 */
@property (nonatomic, copy) NSString *text;

@property (nonatomic, assign) CGSize size;

/**
 * Specifies if the button should automatically set its width and height
 * based on the label.
 */
@property (nonatomic, assign) BOOL automaticWidth;
@property (nonatomic, assign) BOOL automaticHeight;

/**
 * Specifies how to align the label within the button frame.  See documentation for
 * HLLabelNodeVerticalAlignmentMode.  This alignment mode also determines the calculated
 * height used for the button when automaticHeight is true.
 */
@property (nonatomic, assign) HLLabelNodeVerticalAlignmentMode verticalAlignmentMode;

/**
 * The amount of space, when using automatic height or automatic width, to leave between
 * the label and the edge of the button.
 */
@property (nonatomic, assign) CGFloat labelPadX;
@property (nonatomic, assign) CGFloat labelPadY;

@property (nonatomic, copy) NSString *fontName;

@property (nonatomic, assign) CGFloat fontSize;

@property (nonatomic, strong) SKColor *fontColor;

@property (nonatomic, strong) SKColor *color;

@property (nonatomic, assign) CGFloat colorBlendFactor;

@property (nonatomic, assign) CGRect centerRect;

- (instancetype)initWithColor:(SKColor *)color size:(CGSize)size;

- (instancetype)initWithTexture:(SKTexture *)texture;

- (instancetype)initWithImageNamed:(NSString *)name;

@end
