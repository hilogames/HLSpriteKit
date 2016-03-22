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
- (instancetype)initWithTexture:(SKTexture *)texture color:(UIColor *)color size:(CGSize)size;

/// @name Showing and Hiding Messages

/**
 Shows the passed message according to the message node's appearance and animation
 options.

 The message node shows itself by adding itself to the passed parent.  When the message is
 hidden, either automatically or manually, it will remove itself from the parent.
*/
- (void)showMessage:(NSString *)message parent:(SKNode *)parent;

/**
 Immediately hides the currently shown message, if any.

 A hidden message node removes itself from its parent in the node hierarchy.
*/
- (void)hideMessage;

/// @name Configuring Geometry

/**
 The size of the message node background.
*/
@property (nonatomic, assign) CGSize size;

/**
 The anchor point of the message node background.
*/
@property (nonatomic, assign) CGPoint anchorPoint;

/**
 The vertical alignment mode of the message label within the background.

 See `HLLabelNodeVerticalAlignmentMode` for details.
*/
@property (nonatomic, assign) HLLabelNodeVerticalAlignmentMode verticalAlignmentMode;

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
