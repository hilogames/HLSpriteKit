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
@interface HLMessageNode : HLComponentNode <NSCopying>

/// @name Creating a Message Node

- (instancetype)initWithColor:(SKColor *)color size:(CGSize)size NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithImageNamed:(NSString *)name NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithTexture:(SKTexture *)texture NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithTexture:(SKTexture *)texture color:(UIColor *)color size:(CGSize)size NS_DESIGNATED_INITIALIZER;

/// @name Showing and Hiding Messages

- (void)showMessage:(NSString *)message parent:(SKNode *)parent;

- (void)hideMessage;

/// @name Configuring Geometry

@property (nonatomic, assign) CGSize size;

@property (nonatomic, assign) CGPoint anchorPoint;

@property (nonatomic, assign) HLLabelNodeVerticalAlignmentMode verticalAlignmentMode;

/// @name Configuring Appearance

@property (nonatomic, copy) NSString *fontName;

@property (nonatomic, assign) CGFloat fontSize;

@property (nonatomic, strong) SKColor *fontColor;

/// @name Managing Animation

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

@property (nonatomic, copy) NSString *messageSoundFile;

@end
