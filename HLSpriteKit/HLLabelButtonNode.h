//
//  HLLabelButtonNode.h
//  HLSpriteKit
//
//  Created by Karl Voskuil on 5/2/14.
//  Copyright (c) 2014 Hilo. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "HLGestureTarget.h"
#import "SKLabelNode+HLLabelNodeAdditions.h"

@interface HLLabelButtonNode : HLGestureTargetNode <NSCopying, NSCoding, HLGestureTarget>

/**
 * The text of the label in the HLLabelButtonNode.  Layout of the components
 * of the label button will not be performed if the text is unset; during initialization,
 * then, the caller may set the text after setting all other layout-affecting properties,
 * and layout will only be performed once.
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
 * Specifies how to align the label within the button frame.  See
 * documentation for HLLabelNodeVerticalAlignmentMode.  This
 * alignment mode also determines the calculated height used for
 * the button when automaticHeight is true.
 */
@property (nonatomic, assign) HLLabelNodeVerticalAlignmentMode verticalAlignmentMode;

/**
 * The amount of space, when using automatic height or automatic width,
 * to leave between the label and the edge of the button.
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
