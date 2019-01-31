//
//  HLMessageNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 6/2/14.
//  Copyright (c) 2014 Hilo Games. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLComponentNode.h"
#import "SKLabelNode+HLLabelNodeAdditions.h"

typedef NS_ENUM(NSInteger, HLMessageNodeAnimation) {
  HLMessageNodeAnimationSlideLeft,
  HLMessageNodeAnimationSlideRight,
  HLMessageNodeAnimationFade,
};

/**
 HLMessageNode shows a text message over a solid or textured background, with some
 animation options.
*/
@interface HLMessageNode : HLComponentNode <NSCoding, NSCopying>

/// @name Creating a Message Node

/**
 Initializes a new message node, specifying color and size for the background.
*/
- (instancetype)initWithColor:(SKColor *)color size:(CGSize)size;

/**
 Initializes a new message node, specifying an image for the background.
*/
- (instancetype)initWithImageNamed:(NSString *)name;

/**
 Initializes a new message node, specifying a texture for the background.
*/
- (instancetype)initWithTexture:(SKTexture *)texture;

/**
 Initializes a new message node, specifying a texture and size for the background.
*/
- (instancetype)initWithTexture:(SKTexture *)texture color:(SKColor *)color size:(CGSize)size;

/// @name Showing and Hiding Messages

/**
 Shows the passed message according to the message node's appearance and animation
 options.

 The message node shows itself by adding itself to the passed parent.  When the message is
 hidden, either automatically or manually, it will remove itself from the parent.
*/
- (void)showMessage:(NSString *)message parent:(SKNode *)parent;

/**
 Shows the passed message, optionally bypassing the node's animation options.

 Here "animation" refers to the `messageAnimation` and `messageSoundFile`
 during showing.  The message will still linger and hide according to the
 message node's configured animation options.

 The message node shows itself by adding itself to the passed parent.  When the message is
 hidden, either automatically or manually, it will remove itself from the parent.
*/
- (void)showMessage:(NSString *)message animated:(BOOL)animated parent:(SKNode *)parent;

/**
 Immediately hides the currently shown message, if any.

 A hidden message node removes itself from its parent in the node hierarchy.
*/
- (void)hideMessage;

/**
 The message node's message.

 Setting the message here will not change whether the message is currently showing or
 hidden; use `showMessage:parent:` to set a message and show it.
*/
@property (nonatomic, copy) NSString *message;

/// @name Configuring Geometry

/**
 The size of the message node background.

 Default value `14.0`.
*/
@property (nonatomic, assign) CGSize size;

/**
 The anchor point of the message node background.

 Default value `(0.5, 0.5)`.
*/
@property (nonatomic, assign) CGPoint anchorPoint;

/**
 The horizontal alignment mode of the message label within the background.

 Default value `SKLabelVerticalAlignmentModeCenter`.
*/
@property (nonatomic, assign) SKLabelHorizontalAlignmentMode horizontalAlignmentMode;

/**
 A margin used to inset the text from the edge of the background when using a left or
 right horizontal alignment mode; see `horizontalAlignmentMode`.

 Not used when the horizontal alignment mode is center.

 Default value `0.0`.
*/
@property (nonatomic, assign) CGFloat horizontalMargin;

/**
 Specifies how to calculate the message label height when aligning it in the center
 of the background.

 In particular, messages (for most applications) should be baseline-aligned, and
 vertically visually centered in the background.  A good height mode for most fonts to
 achieve that goal is `HLLabelHeightModeFont`.  If that looks like it's leaving too much
 room for the descender, try `HLLabelHeightModeAscenderBias`.

 See `getVerticalAlignmentMode:heightMode:useAlignmentMode:labelHeight:yOffset` in
 `SKLabelNode+HLLabelNodeAdditions.h` for way too much information.

 Default value is `HLLabelHeightModeFont`.
*/
@property (nonatomic, assign) HLLabelHeightMode heightMode;

/// @name Configuring Appearance

/**
 The font used for the message node label.

 Default value is `SKLabelNode` default.
*/
@property (nonatomic, copy) NSString *fontName;

/**
 The font size used for the message node label.

 Default value is `SKLabelNode` default.
*/
@property (nonatomic, assign) CGFloat fontSize;

/**
 The font color used for the message node label.

 Default value is `SKLabelNode` default.
*/
@property (nonatomic, strong) SKColor *fontColor;

/// @name Managing Animation

/**
 The animation used for showing and (automatically) hiding the message node (label and
 background).

 Default value is `HLMessageNodeAnimationSlideLeft`.
*/
@property (nonatomic, assign) HLMessageNodeAnimation messageAnimation;

/**
 Duration for the message animation during show and hide.

 Default value is `0.1`.
*/
@property (nonatomic, assign) NSTimeInterval messageAnimationDuration;

/**
 Duration a message lingers after a call to `showMessage:parent:` before being
 (automatically) hidden.

 Default value is `2.0`.  A value of `0.0` means that the message will not be
 automatically hidden.
*/
@property (nonatomic, assign) NSTimeInterval messageLingerDuration;

/**
 A sound file that will play (by way of `SKAction`) when a message is shown.
*/
@property (nonatomic, copy) NSString *messageSoundFile;

@end
